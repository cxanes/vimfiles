@ECHO off
REM GVIM-SN  %l %c "%f" "%d"
CALL gvim --servername "SN-%~n4" --remote-silent "+cal cursor(%1, %2+1)" "%3"
