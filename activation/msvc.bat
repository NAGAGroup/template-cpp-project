@echo off
setlocal enabledelayedexpansion

if "%CONDA_WINDOWS_ENV_ACTIVE%" neq "1" (
  if not defined PROJECT_ROOT (
    echo PROJECT_ROOT must be set before script activation.
    exit /b 1
  )
  if "%INSTALL_PREFIX%"=="" (
      set "INSTALL_PREFIX=%USERPROFILE%\.local\share\dev"
  )
  
  CALL "%VCINSTALLDIR%/Auxiliary/Build/vcvarsall.bat"
  SET CMAKE_PLAT=
  SET CMAKE_GENERATOR_PLATFORM=
  SET CMAKE_GENERATOR_TOOLSET=
  SET CMAKE_GENERATOR=
  SET CMAKE_GEN=

  REM set "CONDA_CUDA_ROOT=%PREFIX%\targets\x86_64-windows"
  REM if exist "%CONDA_CUDA_ROOT%" (
  REM   set "CUDA_LIB_PATH=%CONDA_CUDA_ROOT%\lib\stubs"
  REM   set "PATH=%CONDA_CUDA_ROOT%\lib;%CONDA_CUDA_ROOT%\lib\stubs;%PATH%"
  REM )

  set "PROJECT_TOOLCHAIN_FILE=%PROJECT_ROOT%\toolchains\windows.cmake"

  if exist "%PROJECT_ROOT%\vcpkg" (
    set "VCPKG_ROOT=%PROJECT_ROOT%\vcpkg"
  )

  set "CONDA_WINDOWS_ENV_ACTIVE=1"
)

endlocal

