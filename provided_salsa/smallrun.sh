#!/bin/bash

echo "WARNING: RUNNING SALSA 1.1.5"

# stage 1 compile
java -cp "salsa1.1.5.jar:." salsac.SalsaCompiler src/*.salsa 
# stage 2 compile
javac -classpath "salsa1.1.5.jar:." src/*.java 

echo Continue? [Enter - Y] / [Anything - N]
userInput=""
read userInput
if [ "$userInput" != "" ]
then
	exit
fi

echo "running"
java -cp "salsa1.1.5.jar:." wwc.naming.WWCNamingServer -p 3030 > /dev/null &
java -cp "salsa1.1.5.jar:." src.Client "input/simple.script"

read -p "Press enter to continue..."