-module(main).
-import(util,[readFile/1,get_all_lines/1,saveFile/2]).
-import(lists,[append/2]). 
-import(string,[substr/3]). 
-import(string,[len/1]). 
% main functions
-export([start_file_server/1, start_dir_service/0, get/2, create/2, quit/1]).

% can access own ual w/ node()
% can acces own PID w/ self()

% you are free (and encouraged) to create helper functions
% but note that the functions that will be called when
% grading will be those below

% when starting the Directory Service and File Servers, you will need
% to register a process name and spawn a process in another node

% starts a directory service
start_dir_service() ->
	Pid = spawn(node(), fun() -> dir_service_receiver([]) end),
	register(dr, Pid).
	% CODE THIS
	% Create new directory service as actor
	% Use spawn in order to run stuff in the background.


% starts a file server with the UAL of the Directory Service
start_file_server(DirUAL) ->
	Pid2 = spawn(file_server_receiver("servers/fs", [])),
	whereis(dr) ! {addFile, Pid2}.
	% CODE THIS
	% Create folder in server
	% name is taken as input 

dir_service_receiver(LS) ->
	FSList = LS,
	receive
		{addFile, FS} ->
			FSList = append(FSList, FS),
			%io:fwrite("~p~n",[file:make_dir(string:concat("servers/", DirUAL))]),
			file:make_dir(string:concat("servers/fs", length(FSList))),
			dir_service_receiver(FSList);
		{g, Arg1, Arg2} ->
			get(Arg1, Arg2),
			dir_service_receiver(FSList);
		{c, Arg1, Arg2} ->
			create(Arg1, Arg2),
			dir_service_receiver(FSList);
		{q} ->
			quit(LS)
	end.

file_server_receiver(FilePath, Chunks) ->
	%receive
		%{q} ->
			%clear folders in servers
		%end.
	pass.

% requests file information from the Directory Service (DirUAL) on File
% then requests file parts from the locations retrieved from Dir Service
% then combines the file and saves to downloads folder
get(DirUAL, File) ->
	pass.
	% CODE THIS
	% Check if downloads (directory/downloads) exists; if not, create it
	% Takes file name as input
	% Find each file part in individual servers
	% Combines them and places in downloads folder

% gives Directory Service (DirUAL) the name/contents of File to create
create(DirUAL, File) ->
	FileStuff = readFile(File),
	Pos = string:chr(File, $.),
	Fad = string:substr(File, 0, Pos-1),
	Step = 1,
	Index = 1,
	Len = len(FileStuff)/64,
	FName = string:join("/servers/fs",Index),
	while(Step < Len+1, FileStuff, Pos, Fad, Step, Index, Len, FName).
	

while(false, FileStuff, Pos, Fad, Step, Index, Len, FName) -> 
	if 
		is_dir(FName) ->
			FName = string:join("/servers/fs",Index),
			FName = string:join(FName, "/"),
			FName = string:join(FName, Fad),
			FName = string:join(FName, "_"),
			FName = string:join(FName, Step/64),
			FName = string:join(FName, ".txt"),
			file:write_file(FName, substr(FileStuff, Step-64, Step - (Step-64)));
		true ->
			Index = 1,
			FName = string:join("/servers/fs",Index),
			FName = string:join(FName, "/"),
			FName = string:join(FName, Fad),
			FName = string:join(FName, "_"),
			FName = string:join(FName, Step/64),
			FName = string:join(FName, ".txt"),
			file:write_file(FName, substr(FileStuff, Step-64, Step - (Step-64)))
	end.
while(Checker, FileStuff, Pos, Fad, Step, Index, Len, FName) ->
	if 
		is_dir(FName) ->
			FName = string:join("/servers/fs",Index),
			FName = string:join(FName, "/"),
			FName = string:join(FName, Fad),
			FName = string:join(FName, "_"),
			FName = string:join(FName, Step/64),
			FName = string:join(FName, ".txt"),
			file:write_file(FName, substr(FileStuff, Step, 64)),
			while(Step+64 < Len+1, FileStuff, Pos, Fad, Step+1, Index+1, Len, string:join("/servers/fs",Index+1));
		true ->
			Index = 1,
			FName = string:join("/servers/fs",Index),
			FName = string:join(FName, "/"),
			FName = string:join(FName, Fad),
			FName = string:join(FName, "_"),
			FName = string:join(FName, Step/64),
			FName = string:join(FName, ".txt"),
			file:write_file(FName, [substr(FileStuff, Step, 64)]),
			while(Step+64 < Len+1, FileStuff, Pos, Fad, Step+1, Index+1, Len, string:join("/servers/fs",Index+1))
	end.


	% CODE THIS
	% Takes file from input folder.
	% Split file into file parts and send them through the file servers in rotation

% sends shutdown message to the Directory Service (DirUAL)
quit(DirUAL) ->
	pass.
	% CODE THIS




%Client: Specify file name, located in same directory. Server created in folder. Specify from this working directory, go and get file from here.
%Salse - java, can use java objects
%Erlang - more common, more support