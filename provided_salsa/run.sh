#!/bin/bash

echo "WARNING: RUNNING SALSA 1.1.5"

# stage 1 compile
java -cp "salsa1.1.5.jar:." salsac.SalsaCompiler src/*.salsa 
# stage 2 compile
javac -classpath "salsa1.1.5.jar:." src/*.java 

rm -rf "downloads"
rm -rf "server"

if [ "$1" == "" ]
then
	echo Continue? [Enter - Y] / [Anything - N]
	userInput=""
	read userInput
	if [ "$userInput" != "" ]
	then
		exit
	fi
fi

## Run the compiled code ##

echo "running"
mkdir "downloads"
java -cp "salsa1.1.5.jar:." wwc.naming.WWCNamingServer -p 3030 > downloads/namingServer.txt &
server=$!
java -cp "salsa1.1.5.jar:." wwc.messaging.Theater 4040 > downloads/theater1.txt &
theater1=$!
java -cp "salsa1.1.5.jar:." wwc.messaging.Theater 4041 > downloads/theater2.txt &
theater2=$!
java -cp "salsa1.1.5.jar:." wwc.messaging.Theater 4042 > downloads/theater2.txt &
theater3=$!
java -cp "salsa1.1.5.jar:." src.Client simple.script &
client=$!

## Wait for execution to terminate ##

echo "Waiting 5 seconds."
echo
read -t 5 -p ""

## terminate the processes we launched ##
kill $server 2> /dev/null
kill $theater1 2> /dev/null
kill $theater2 2> /dev/null
kill $theater3 2> /dev/null
kill $client 2> /dev/null

echo 
echo "Execution terminated."

echo

## Check if the inputs match the outputs ##
# 0 is a pass (cmp found no differences)

cmp -s input/a.txt input/a.txt
a_result=$?
echo "a:" $a_result
if [ $a_result == 0 ]
then
	echo a passed.
else
	echo a failed.
fi

cmp -s input/b.txt downloads/b.txt
b_result=$?
echo "b:" $b_result
if [ $b_result == "0" ]
then
	echo b passed.
else
	echo b failed.
fi

echo " "
echo "Pressing enter will delete the output files."
echo "Check their contents now."
echo " "
read -p "Press enter to continue..."


rm -rf downloads
rm -rf servers
