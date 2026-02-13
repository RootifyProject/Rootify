@echo off
REM
REM  Copyright (C) 2026 Rootify - Aby - FoxLabs
REM
REM  Licensed under the Apache License, Version 2.0 (the "License");
REM  you may not use this file except in compliance with the License.
REM  You may obtain a copy of the License at
REM
REM       http://www.apache.org/licenses/LICENSE-2.0
REM
REM  Unless required by applicable law or agreed to in writing, software
REM  distributed under the License is distributed on an "AS IS" BASIS,
REM  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM  See the License for the specific language governing permissions and
REM  limitations under the License.
REM

REM Rootify Build & Run Wrapper for Windows

set CMD=%1
if "%CMD%"=="" goto usage
if "%CMD%"=="-help" goto usage
if "%CMD%"=="--help" goto usage

shift

set FLAGS=
set FLUTTER_ARGS=

:check_env
echo --- Checking Environment Health ---
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: Flutter SDK not found in PATH.
    exit /b 1
)
echo Environment OK.
echo ----------------------------------

:loop
if "%~1"=="" goto endloop
if "%~1"=="-alpha" set FLAGS=%FLAGS% -Pctx=alpha& shift & goto loop
if "%~1"=="-beta"  set FLAGS=%FLAGS% -Pctx=beta& shift & goto loop
if "%~1"=="-rc"    set FLAGS=%FLAGS% -Pctx=rc& shift & goto loop
if "%~1"=="-stable" set FLAGS=%FLAGS% -Pctx=stable& shift & goto loop
if "%~1"=="-p"     set FLUTTER_ARGS=%FLUTTER_ARGS% --profile& shift & goto loop
if "%~1"=="-d"     set FLUTTER_ARGS=%FLUTTER_ARGS% --debug& shift & goto loop
if "%~1"=="-r"     set FLUTTER_ARGS=%FLUTTER_ARGS% --release& shift & goto loop
set FLUTTER_ARGS=%FLUTTER_ARGS% %~1
shift
goto loop

:endloop

if "%CMD%"=="run" (
    echo Executing Rootify Run (%FLAGS%)...
    flutter run %FLUTTER_ARGS% %FLAGS%
) else if "%CMD%"=="build" (
    echo Orchestrating Rootify Build (%FLAGS%)...
    flutter build apk --release --split-per-abi %FLUTTER_ARGS% %FLAGS%
) else (
    echo Unknown command: %CMD%
    exit /b 1
)
goto :eof

:usage
echo ==========================================================
echo        ROOTIFY CLI UTILITY - WINDOWS TOOLKIT          
echo ==========================================================
echo Usage: rify.bat [command] [context-flags] [mode-flags] [args]
echo.
echo COMMANDS:
echo   run                Execute the app on a target device.
echo   build              Generate production-ready binaries.
echo.
echo CONTEXT FLAGS (Maps to Gradle -Pctx=[context]):
echo   -alpha             Internal testing. (ctx=alpha)
echo   -beta              Feature testing. (ctx=beta)
echo   -rc                Release Candidate. (ctx=rc)
echo   -stable            Production release. (ctx=stable)
echo.
echo MODE SELECTION:
echo   -d                 Debug Mode   (Standard JIT)
echo   -p                 Profile Mode (Performance AOT)
echo   -r                 Release Mode (Standard AOT)
echo.
echo MANUAL COMMAND EQUIVALENTS:
echo   # Run Beta build in Profile mode
echo   flutter run --profile -Pctx=beta
echo   # or: flutter run -profile -Pbeta
echo.
echo   # Build Stable Production APKs
echo   flutter build apk --release --split-per-abi -Pctx=stable
echo   # or: flutter build apk --release -Pstable
echo.
echo   # Standard Build Pattern
echo   # Release Build (Without ctx)
echo   flutter build apk --release
echo   # or: flutter build apk -release
echo.
echo   # Debug Build (Without ctx)
echo   flutter build apk --debug
echo   # or: flutter build apk -debug
echo.
echo   # Profile Build (Without ctx)
echo   flutter build apk --profile
echo   # or: flutter build apk -profile
echo.
echo ENVIRONMENT:
echo   - Flutter SDK      Stable channel.
echo   - JDK 17           Required for Gradle.
echo   - JAVA_HOME        Must point to JDK 17.
echo   - Signing          key.properties (Fallback to Debug).
echo.
echo EXAMPLES:
echo   rify.bat run -beta -p      # Run Beta build in Profile mode
echo   rify.bat build -stable     # Build Stable production APKs
echo   rify.bat -help             # Show this documentation
echo ==========================================================
exit /b 0
