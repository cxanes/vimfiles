@ECHO OFF

START "" clewn -nb:localhost:3219:xxx
START "" "C:\Program Files\Vim\vim72\gvim.exe" -R -nb:localhost:3219:xxx
