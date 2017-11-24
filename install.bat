::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: This script will search for the files produced by CMake and copy them to an
:: installation directory.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off
cls

set buildDir="%~dp0..\__build-output"
set installDir="%~dp0..\__install-output"

:: Get the absolute path result is returned in the second parameter
call :ResolvePath %installDir% installDir

@echo ********************************************************************************
@echo * Copying files to: %installDir%

:: List all subdirectories recursively
@for /d /r %buildDir% %%D in (*) do @(
  :: Check if the current directory name "%%~nD" is the build output directory
  if "Win32" == "%%~nD" @(
    call :CopyFiles %%D %installDir% 
  )
  if "x64" == "%%~nD" @(
    call :CopyFiles %%D %installDir% 
  )
)

@echo.
@echo --- Destination: %installDir%
@echo.

:: Recuresively list all .bat files
@for /r %~dp0 %%F in (*.bat) do (
  :: Exclude the current .bat file
  @if not "%~dpnx0" == "%%F" (
    @echo Copying: %%~nxF
    copy /y %%F %installDir%
  )
)

@echo * Done copying...
@echo ********************************************************************************

goto :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Subroutines
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Subroutine
::     CopyFiles
:: Description:
::     Copies files from one directory to another.
:: Parameters:
::     %1 - The directory to copy from.
::     %2 - The directory to copy to.
:CopyFiles
  set sourcePath=%1
  set targetPath=%2

  :: Get the last subdirectory name
  set remainingTokens=%sourcePath%
  :CopyFiles_Parse
  :: Walks the string "%remainingTokens%" and splits it at '\' as a delimiter
  @for /f "tokens=1* delims=\" %%D in ("%remainingTokens%") do @(
    :: Goes on until there are no more tokens
    if not "" == %%D (
      set parentDir=%%D
      :: %%E is an additional variable allocated by "tokens=1*" following %%D
      set remainingTokens=%%E
      goto :CopyFiles_Parse
    )
  )
  
  set targetPath="%targetPath:~1,-1%\%parentDir%"
  
  if not exist %targetPath% (
    mkdir %targetPath%
  )

  @echo.
  @echo --- Destination: %targetPath%
  @echo.

  :: Lists all files recursively
  for /r %sourcePath% %%F in (*) do @(
    @echo Copying: %%~nxF
    copy /y %%F %targetPath%
  )

  :: End the subroutine
  @exit /b

:: Subroutine:
::     ResolvePath
:: Description:
::     Resolves a relative path and return an absolute path as a second output
::     parameter.
:: Parameters:
::     %1 (in)  - A relative path
::     %2 (out) - The absolute path
:ResolvePath
  set %2="%~f1"
  :: End the subroutine
  @exit /b
