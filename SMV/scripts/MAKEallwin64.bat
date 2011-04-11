@echo off

Rem  Windows batch file to copy smokediffset SVNROOT=~/FDS-SMV

Rem setup environment variables (defining where repository resides etc) 

set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% GOTO endif_envexist
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use SMV/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...
pause>NUL
goto:eof

:endif_envexist

call %envfile%

%svn_drive%

call %svn_root%\SMV\scripts\MAKEsmdwin64.bat
call %svn_root%\SMV\scripts\MAKEbgwin64.bat
call %svn_root%\SMV\scripts\MAKEsmzwin64.bat
call %svn_root%\SMV\scripts\MAKEf2awin64.bat
