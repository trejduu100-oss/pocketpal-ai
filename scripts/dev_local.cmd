@echo off
REM CrywereGPT local dev setup script for Windows (cmd)
REM - Installs dependencies for backend and web (if present)
REM - Builds or starts the web dev server
REM - Starts the backend server (if present)
REM - Designed to run on Windows (cmd.exe)

SETLOCAL ENABLEDELAYEDEXPANSION

REM Resolve script directory
SET SCRIPT_DIR=%~dp0
REM parent directory (repo root)
PUSHD %SCRIPT_DIR%\.. 

ECHO == CrywereGPT Local Dev Setup ==

REM Backend
IF EXIST backend (
  ECHO --> Found backend\ directory. Installing backend dependencies...
  PUSHD backend
  IF EXIST package-lock.json (
    call npm ci || call npm install
  ) ELSE (
    IF EXIST package.json (
      call npm install
    )
  )

  IF EXIST server.js (
    ECHO --> Starting backend (node server.js) in new window on default port 5000...
    start "CrywereGPT Backend" cmd /c "node server.js"
    ECHO --> Backend started (check the new window for logs)
  ) ELSE (
    ECHO --> No server.js found in backend\ — skipping auto-start.
  )
  POPD
) ELSE (
  ECHO --> No backend\ folder found. Skipping backend setup.
)

REM Web
IF EXIST web (
  ECHO --> Found web\ directory. Installing web dependencies...
  PUSHD web
  IF EXIST package-lock.json (
    call npm ci || call npm install
  ) ELSE (
    IF EXIST package.json (
      call npm install
    )
  )

  REM Check for dev or start scripts in package.json
  powershell -NoProfile -Command ^
    "if (Test-Path package.json) { (Get-Content package.json -Raw) -match '"dev"' }" >nul 2>&1
  IF %ERRORLEVEL% EQU 0 (
    ECHO --> Running: npm run dev
    call npm run dev
  ) ELSE (
    powershell -NoProfile -Command ^
      "if (Test-Path package.json) { (Get-Content package.json -Raw) -match '"start"' }" >nul 2>&1
    IF %ERRORLEVEL% EQU 0 (
      ECHO --> Running: npm start
      call npm start
    ) ELSE (
      ECHO --> No dev/start script found. Building static site and serving on port 3000...
      call npm run build
      REM Try to use 'serve' if available, otherwise instruct user
      where serve >nul 2>&1
      IF %ERRORLEVEL% EQU 0 (
        serve -s build -l 3000
      ) ELSE (
        ECHO ---- 'serve' not found. Install it with: npm i -g serve
        ECHO ---- After install run: serve -s build -l 3000
      )
    )
  )
  POPD
) ELSE (
  REM fallback to root package.json
  IF EXIST package.json (
    ECHO --> No web\ folder but found root package.json. Installing and starting root app...
    IF EXIST package-lock.json (
      call npm ci || call npm install
    ) ELSE (
      call npm install
    )

    powershell -NoProfile -Command ^
      "(Get-Content package.json -Raw) -match '"dev"'" >nul 2>&1
    IF %ERRORLEVEL% EQU 0 (
      call npm run dev
    ) ELSE (
      powershell -NoProfile -Command ^
        "(Get-Content package.json -Raw) -match '"start"'" >nul 2>&1
      IF %ERRORLEVEL% EQU 0 (
        call npm start
      ) ELSE (
        ECHO --> No dev/start script at root. Nothing to start for web UI.
      )
    )
  ) ELSE (
    ECHO --> No web\ or root package.json found. Skipping web setup.
  )
)

POPD

ECHO.
ECHO == Summary ==
ECHO Backend: check for running window titled "CrywereGPT Backend" or logs in backend\.
ECHO Web: if started, check http://localhost:3000 or the dev server's port.
ECHO If you need to build llama.cpp locally (native inference), see docs\PLATFORM.md for build instructions.

ENDLOCAL
