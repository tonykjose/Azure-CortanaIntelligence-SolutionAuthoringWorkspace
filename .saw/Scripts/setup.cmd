@ECHO OFF

rem               Welcome to
rem    ____    _____     ____       _____  
rem   / ___)  (_   _)   / __ \     / ____\ 
rem  / /        | |    / /  \ \   ( (___   
rem ( (         | |   ( (    ) )   \___ \  
rem ( (         | |   ( (  /\) )       ) ) 
rem  \ \___    _| |__  \ \_\ \/    ___/ /  
rem   \____)  /_____(   \___\ \_  /____/   
rem                          \__)           
rem     Solution Authoring Workbench (SAW)
rem
rem
rem  >> DIRECTIONS
rem  
rem  If you haven't done so already, run this program to setup
rem  a new solution authoring environment. In VS Code Web (App
rem  Service Editor) that is as easy as clicking the ▶ `Run from
rem  Console` button in the top right corner.
rem
rem  Enjoy!










rem TODO: make this more robust.
IF EXIST "%~dp0\build.cmd" EXIT /B 1

git init .
git remote add -t * -f origin https://github.com/wdecay/ciqsauthoring
git checkout -f master
.saw/Scripts/build.cmd