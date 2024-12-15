@echo off
setlocal enabledelayedexpansion

if not "%CONDA_WINDOWS_ENV_ACTIVE%"=="1" (
  call "%PROJECT_ROOT%\activation\msvc.bat"
)

if "%CONDA_CLANG_ENV_ACTIVE%"=="0" (
  SET CXX="%CONDA_PREFIX%/Library/bin/clang++.exe"
  SET CC="%CONDA_PREFIX%/Library/bin/clang.exe"
  SET LDFLAGS=
)
