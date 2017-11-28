@echo off

cls

REM Loop over the two platforms in awkward batch file fashion.
set PLATFORM=None
:PLATFORMLOOPHEAD
IF %PLATFORM% == x64 GOTO PLATFORMLOOPEND
IF %PLATFORM% == Win32 SET PLATFORM=x64
IF %PLATFORM% == None SET PLATFORM=Win32


setlocal EnableDelayedExpansion
:: Version number or range needs to be in quotes
call :FindVS2017 "15.0" "vs2017" %PLATFORM%
if !ERRORLEVEL! == 0 (
  set SUCCESS=1
) else (
  set SUCCESS=0
)

GOTO PLATFORMLOOPHEAD

:PLATFORMLOOPEND

IF %SUCCESS% == 1 goto DONE
echo Failed to find MSBuild toolsets directory.
goto FAILED

:DONE
  echo Done!
  goto END

:FAILED
  echo MSVC integration install failed.
  pause
  goto END

:END
  endlocal & goto :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Description:
::   Locates Visual Studio versions
:: Parameter:
::   %1 - Visual Studio version number to find. The parameter needs to be quoted
::        and can be a range e.g "15.0", "[15.0,16.0)", etc.
::   %2 - Visual Studio version as set in CMakeLists.txt e.g. "vs2017"
::   %3 - Platform
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
: FindVS2017
  set "D=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
  if exist "%D%\vswhere.exe" (
    set "vswhereDir=%D%"
  ) else (
    :: Use %ProgramFiles% in a 32-bit program prior to Windows 10
    set D="%ProgramFiles%\Microsoft Visual Studio\Installer"
    if exist "%D%\vswhere.exe" (
      set "vswhereDir=%D%"
    ) else (
      @echo vswhere.exe not found
      goto :eof
    )
  )
  set errorOnCopy=0 :: No error
  set command=`vswhere -prerelease -version %1% -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`
  pushd "%vswhereDir%"
   for /f "usebackq delims=" %%i in (%command%) do (
     call :ToolsetsDirFound "%%i\Common7\IDE\VC\VCTargets\Platforms\%3\PlatformToolsets" %2 %3
     if not !ERRORLEVEL! == 0 (
        :: Copy failed
        set errorOnCopy=1
     )
   )
  popd
  exit /b %errorOnCopy%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Description:
::   Echoes a detected toolset directory
:: Parameter:
::   %1 - A toolset directory
::   %2 - Visual Studio version as defined in CMakeLists.txt"
::   %3 - Platform
:: Return value: 
::   ERRORLEVEL: 1 - success, 0 - failure
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ToolsetsDirFound
  :: Remove the surrounding quotes
  set "PD=%~1"
  set VS_VER=%~2
  set Platform=%~3
  set "TD=%~1\LLVM-%VS_VER%"
  if exist "%PD%" (
    @echo Visual Studio 2017 PlatformToolsets found at:
    @echo     "%PD%"
    :: Copy files
    IF EXIST "%TD%" (
      echo Toolset found at:
      echo     "%TD%"
      exit /b 0
    ) else (
      echo Toolset NOT found at:
      echo     "%TD%"
      exit /b 1
    )
    :: Create directories
    ::IF NOT EXIST "%TD%" mkdir "%TD%"
    ::IF NOT %ERRORLEVEL% == 0 GOTO Copy_FAILED
    ::IF NOT EXIST "%TD%_xp" mkdir "%TD%_xp"
    ::IF NOT %ERRORLEVEL% == 0 GOTO Copy_FAILED
    :: Copy main toolset.props
    ::copy "%Platform%\toolset-%VS_VER%.props" "%TD%\toolset.props"
    ::IF NOT %ERRORLEVEL% == 0 GOTO Copy_FAILED
    ::copy "%Platform%\toolset-%VS_VER%.targets" "%TD%\toolset.targets"
    ::IF NOT %ERRORLEVEL% == 0 GOTO Copy_FAILED
    :: Copy xp toolset.props
    ::copy "%Platform%\toolset-%VS_VER%_xp.props" "%TD%_xp\toolset.props"
    ::IF NOT %ERRORLEVEL% == 0 GOTO Copy_FAILED
    ::copy "%Platform%\toolset-%VS_VER%_xp.targets" "%TD%_xp\toolset.targets"
    ::IF NOT %ERRORLEVEL% == 0 GOTO Copy_FAILED
    exit /b 0
  :Copy_FAILED
    exit /b 1
  ) else (
    @echo Directory not found: 
    @echo     "%PD%"
    :: FAILURE
    exit /b 1
  )
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

pause