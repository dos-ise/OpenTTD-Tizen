@echo off
echo ================================================
echo Building and extracting OpenTTD.wgt from Docker
echo ================================================
echo.

REM Move to repo root (two levels up from os\tizen\)
cd /d "%~dp0..\.."

echo [1/6] Building Docker image...
docker build -f os/tizen/Dockerfile -t openttd-tizen .
if errorlevel 1 (
    echo ERROR: Docker image build failed!
    pause
    exit /b 1
)

echo [2/6] Creating temporary container...
docker create --name openttd-tmp openttd-tizen
if errorlevel 1 (
    echo ERROR: Failed to create container!
    pause
    exit /b 1
)

echo [3/6] Starting container...
docker start openttd-tmp
if errorlevel 1 (
    echo ERROR: Failed to start container!
    docker rm openttd-tmp
    pause
    exit /b 1
)

echo [4/6] Waiting...
timeout /t 2 /nobreak >nul

echo [5/6] Copying OpenTTD.wgt...
docker cp openttd-tmp:/home/openttd/OpenTTD.wgt "OpenTTD.wgt"
if errorlevel 1 (
    echo ERROR: Failed to copy file!
    docker stop openttd-tmp
    docker rm openttd-tmp
    pause
    exit /b 1
)

echo [6/6] Cleaning up...
docker stop openttd-tmp
docker rm openttd-tmp

echo.
echo ================================================
echo SUCCESS! OpenTTD.wgt extracted successfully.
echo ================================================
pause
