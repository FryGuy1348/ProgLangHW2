ECHO OFF 

:: Stage 1 compile
java -cp salsa1.1.6.jar;. salsac.SalsaCompiler src/*.salsa 
:: Stage 2 compile 
javac -classpath salsa1.1.6.jar;. src/*.java


rmdir /S /Q out


echo.
echo.
:PROMPT
SET /P AREYOUSURE=Continue? [Enter - Y] / [Anything - N]
IF /I "%AREYOUSURE%" NEQ "" EXIT /B
echo.
echo.


START CMD /C CALL "boot.bat" "0"
:: START CMD /C CALL "boot.bat" "1"


java -cp salsa1.1.6.jar;. src.Client "input/simple.script"


echo.
echo.
pause
