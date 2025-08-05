@echo off
setlocal ENABLEDELAYEDEXPANSION

REM ===============================================
REM Configure source MP3 folder (script's current directory):
REM ===============================================
set "MP3_FOLDER=%CD%"

REM === Prompt for target drive ===
:ask_drive
cls
echo.
echo ===============================
echo   USB Drive Selection
echo ===============================
echo Please enter the target USB drive letter (e.g., F):
set /p TARGET_DRIVE="Drive Letter: "
set "TARGET_DRIVE=%TARGET_DRIVE%:"

REM === Check if the drive exists ===
if not exist %TARGET_DRIVE%\ (
    echo ERROR: The drive %TARGET_DRIVE% does not exist.
    echo Please enter a valid drive.
    pause
    goto ask_drive
)

REM === Check if the drive is removable using PowerShell ===
for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "(Get-Volume -DriveLetter '%TARGET_DRIVE:~0,1%').DriveType"` ) do (
    set "DRIVE_TYPE=%%A"
)

if not defined DRIVE_TYPE (
    echo ERROR: Could not determine drive type for %TARGET_DRIVE%.
    echo Ensure the drive is inserted and accessible.
    pause
    exit /b 1
)

if /i not "%DRIVE_TYPE%"=="Removable" (
    echo ERROR: The drive %TARGET_DRIVE% is NOT a removable USB drive!
    echo Formatting is only allowed for removable drives.
    pause
    exit /b 1
)

echo Detected: %TARGET_DRIVE% is a removable USB drive.

for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "(Get-Volume -DriveLetter '%TARGET_DRIVE:~0,1%').Size / 1MB"` ) do (
    set /a DRIVE_SIZE_MB=%%A
for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "(Get-Volume -DriveLetter '%TARGET_DRIVE:~0,1%').Size / 1MB"` ) do (
    set /a DRIVE_SIZE_MB=%%A
)

REM === Ensure drive size was correctly retrieved ===
if not defined DRIVE_SIZE_MB (
    echo ERROR: Could not determine drive size for %TARGET_DRIVE%.
    echo Ensure the drive is inserted and accessible.
    pause
    exit /b 1
)

echo Detected Drive Size: %DRIVE_SIZE_MB% MB

REM === Check if size is within range (64MB - 4GB) ===
if %DRIVE_SIZE_MB% LSS 64 (
    echo The drive %TARGET_DRIVE% is too small!
    echo It must be between 64MB and 4096MB.
    pause
    exit /b 1
)
if %DRIVE_SIZE_MB% GTR 4096 (
    echo The drive %TARGET_DRIVE% is too large!
    echo It must be between 64MB and 4096MB.
    pause
    exit /b 1
)

echo.
echo ==============================================
echo   Formatting %TARGET_DRIVE% as FAT32...
echo ==============================================
format %TARGET_DRIVE% /FS:FAT32 /Q /V:MP3_DRIVE /X

REM === Check if formatting was successful ===
if %errorlevel% NEQ 0 (
    echo ERROR: Formatting failed.
    pause
    exit /b 1
)

echo.
echo ==============================================
echo   Copying MP3 files to %TARGET_DRIVE%...
echo ==============================================

REM === Copy MP3 files in ascending order ===
pushd "%MP3_FOLDER%"
for /f "tokens=* delims=" %%F in ('dir /b /o:n "%MP3_FOLDER%\*.mp3"') do (
    echo Copying "%%F" to "%TARGET_DRIVE%\"
    copy "%MP3_FOLDER%\%%F" "%TARGET_DRIVE%\" >nul
)
popd

echo.
echo All MP3 files copied successfully.
echo Done!
pause
exit /b 0
