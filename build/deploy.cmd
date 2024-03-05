@echo off
cls
setlocal

set sourcedir=%1
set targetdir=%2
echo source: %sourcedir%
echo target: %targetdir%
echo deleting existing files in target
rmdir /s /q %targetdir%

echo deploying addon from source to target
xcopy %sourcedir%\*.* %targetdir% /c /y /q /e /i