@ECHO off
CALL gvim --servername SN -u NORC --cmd "if v:servername=='SN'|ru _vimrc|el|se lpl|en" --remote-silent "+cal cursor(%1, %2+1)" "%3"
