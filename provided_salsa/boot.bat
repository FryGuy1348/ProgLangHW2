
ECHO OFF

echo Boot option %1

if %1 == "0" java -cp salsa1.1.6.jar;. wwc.naming.WWCNamingServer -p 3030
if %1 == "1" java -cp salsa1.1.6.jar;. wwc.messaging.Theater 4040
if %1 == "2" java -cp salsa1.1.6.jar;. wwc.messaging.Theater 4041

:: pause