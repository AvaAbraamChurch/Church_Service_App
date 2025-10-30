@echo off
echo ========================================
echo Remote Config Cloud Functions Deployment
echo ========================================
echo.

cd functions

echo Installing dependencies...
call npm install

echo.
echo Deploying Cloud Functions to Firebase...
call firebase deploy --only "functions"

echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Your Cloud Functions are now live:
echo - updateRemoteConfig
echo - getRemoteConfig
echo.
echo You can now use the Admin Dashboard to update Remote Config values.
echo.
pause

