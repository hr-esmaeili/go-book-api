@echo off
REM Windows deployment script for Go Book API
REM This script builds and packages the application for deployment

set APP_NAME=go-book-api
set BUILD_DIR=bin
set DEPLOY_DIR=deploy
set TAR_FILE=%APP_NAME%.tar.gz

echo Starting Windows deployment preparation of %APP_NAME%...

REM Check if go.mod exists
if not exist "go.mod" (
    echo Error: go.mod not found. Please run this script from the project root.
    exit /b 1
)

REM Build the application
echo Building application...
go build -o %BUILD_DIR%\%APP_NAME%.exe ./cmd

if not exist "%BUILD_DIR%\%APP_NAME%.exe" (
    echo Error: Build failed. Binary not found.
    exit /b 1
)

echo Build successful!

REM Create deployment package
echo Creating deployment package...
if exist %DEPLOY_DIR% rmdir /s /q %DEPLOY_DIR%
mkdir %DEPLOY_DIR%

REM Copy necessary files
copy %BUILD_DIR%\%APP_NAME%.exe %DEPLOY_DIR%\%APP_NAME%
xcopy app %DEPLOY_DIR%\app\ /e /i
copy go.mod %DEPLOY_DIR%\
copy go.sum %DEPLOY_DIR%\
copy Makefile %DEPLOY_DIR%\
copy README.md %DEPLOY_DIR%\

REM Create tar archive using PowerShell
echo Creating tar archive...
powershell -Command "Compress-Archive -Path '%DEPLOY_DIR%\*' -DestinationPath '%TAR_FILE%' -Force"

echo Deployment package created: %TAR_FILE%
echo.
echo To deploy to your server:
echo 1. Upload %TAR_FILE% and one of the deploy scripts to your server
echo 2. Extract the tar file: tar -xzf %TAR_FILE%
echo 3. Run the appropriate deploy script:
echo    - deploy-no-sudo.sh (for user-level deployment)
echo    - deploy-docker.sh (for Docker deployment)
echo    - deploy-simple.sh (for simple binary deployment)
echo.
echo Note: The original deploy.sh requires sudo privileges.
