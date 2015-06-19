@ECHO OFF
SETLOCAL
SET EL=0

ECHO CWD^: %CD%
SET PATH=%HOME%;%PATH%

IF DEFINED SKIP_DL IF %SKIP_DL% EQU 1 GOTO RUN_INSTALL

REM find and remove default node.exe to avoid conflicts
FOR /F "tokens=*" %%i in ('node -e "console.log(process.execPath)"') do SET NODE_EXE_PATH=%%i
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO deleting node.exe^: %NODE_EXE_PATH%

IF EXIST %NODE_EXE_PATH% DEL /Q %NODE_EXE_PATH%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

SET ARCHPATH=
if "%platform%"=="x64" SET ARCHPATH=x64/
SET NODE_URL=https://mapbox.s3.amazonaws.com/node-cpp11/v%NODE_VERSION%/%ARCHPATH%node.exe
ECHO fetching %NODE_URL%
powershell Invoke-WebRequest $env:NODE_URL -OutFile $env:HOME\node.exe
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

SET VCREDIST_FILE=vcredist_%platform%-mini.7z
SET VCREDIST_URL=https://mapbox.s3.amazonaws.com/windows-builds/visual-studio-runtimes/vcredist-VS2014-CTP4/%VCREDIST_FILE%
ECHO fetching %VCREDIST_URL%
IF NOT EXIST %HOME%\%VCREDIST_FILE% powershell Invoke-WebRequest $env:VCREDIST_URL -OutFile $env:HOME\$env:VCREDIST_FILE
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
7z e %VCREDIST_FILE%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:RUN_INSTALL

node -v
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
node -e "console.log(process.argv,process.execPath,process.arch)"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
CALL npm -v
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


CALL npm install --fallback-to-build=false --toolset=v140
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

REM put dumpbin on path: required by check_shared_libs.py
SET PATH=C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin;%PATH%
python test\check_shared_libs.py .\
ECHO ========== TODO ENABLE AGAIN ======== IF %ERRORLEVEL% NEQ 0 GOTO ERROR
CALL npm test
ECHO ========== TODO ENABLE AGAIN ======== IF %ERRORLEVEL% NEQ 0 GOTO ERROR
node test/test-client.js
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
ECHO ============== ERRORLEVEL^: %EL% ===============

:DONE
ECHO ============= DONE ===============
CD %HOME%
EXIT /b %EL%



environment:
  HOME: "c:\\projects\\tm2"
  AWS_ACCESS_KEY_ID:
    secure: "yr0cfv7H8uVu2iyIn93+brMT6oEhvm9FpkJPvwGZMlA="
  AWS_SECRET_ACCESS_KEY:
    secure: "cqTj03yqur/yCYCrMI0+A2ttBJ5r7uA8Xb0i0prEcM7lDLczYssPdp3DnqUnvIPN"
  matrix:
    - NODE_VERSION: 0.10.33
      platform: x64
    - NODE_VERSION: 0.10.33
      platform: x86

shallow_clone: true

install:
  # find and remove default node.exe to avoid conflicts
  - node -e "console.log(process.execPath)" > node_path.txt
  - SET /p NODE_EXE_PATH=<node_path.txt
  - del node_path.txt
  - del /q /s "%NODE_EXE_PATH%"
  # add local node to path
  - SET PATH=%CD%;%PATH%;
  - SET ARCHPATH=
  - if %platform% == x64 (SET ARCHPATH=x64/)
  - ps: Write-Output "fetching https://mapbox.s3.amazonaws.com/node-cpp11/v${env:NODE_VERSION}/${env:ARCHPATH}node.exe"
  - ps: Start-FileDownload "https://mapbox.s3.amazonaws.com/node-cpp11/v${env:NODE_VERSION}/${env:ARCHPATH}node.exe"
  - ps: Write-Output "https://mapbox.s3.amazonaws.com/windows-builds/visual-studio-runtimes/vcredist-VS2014-CTP4/vcredist_$env:platform.exe"
  - ps: Start-FileDownload "https://mapbox.s3.amazonaws.com/windows-builds/visual-studio-runtimes/vcredist-VS2014-CTP4/vcredist_$env:platform.exe"
  - .\vcredist_%platform%.exe /q /norestart
  - node -v
  - node -e "console.log(process.argv,process.execPath,process.arch)"
  - npm -v
  - npm install --fallback-to-build=false --toolset=v140
  # put dumpbin on path: required by check_shared_libs.py
  - SET PATH=C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin;%PATH%
  - python test\check_shared_libs.py .\
  - npm test
  - node test/test-client.js

build: off
test: off
deploy: off
