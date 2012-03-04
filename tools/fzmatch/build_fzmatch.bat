@ECHO off

REM CALL "C:\Program Files\Microsoft Visual Studio 8\Common7\Tools\vsvars32.bat"
call "%VS100COMNTOOLS%\vsvars32.bat"

cl fzmatch.c /O2 /link /DLL /OUT:fzmatch.dll

