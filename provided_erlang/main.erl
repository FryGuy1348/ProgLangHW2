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
			FS = spawn(file_server_receiver(string:concat("servers/fs", length(FSList)), [])),
			FSList = append(FSList, FS),
			%io:fwrite("~p~n",[file:make_dir(string:concat("servers/", DirUAL))]),
			file:make_dir(string:concat("servers/fs", length(FSList))),
			dir_service_receiver(FSList);
		%Perform Get operations
		{g, Arg1, Arg2} ->
			
			dir_service_receiver(FSList);
		%Perform Create operations (Arg1 = DirUal, Arg2 = File)
		{c, Arg1, Arg2} ->
			FileStuff = readFile(string:concat("input/",Arg2)),
			Pos = string:chr(Arg2, $.),
			%Get file name separate from .txt
			Fad = string:substr(Arg2, 0, Pos-1),
			Step = 1,
			Index = 1,
			Len = len(FileStuff)/64,
			FName = string:join("/servers/fs",Index),
			%Go through while loop and split up chunks among file servers
			while(Step < Len+1, FileStuff, Pos, Fad, Step, Index, Len, FName, FSList),
			dir_service_receiver(FSList);
		{addPart, ID, Part, Index} ->
			list:nth(Index-1, FSList) ! {addChunk, ID, Part};
		%Send Quit command to all file servers
		{q} ->
			
	end.

file_server_receiver(FilePath, Chunks) ->
	receive
		{addChunk, Chunk} ->
			Chunks = append(Chunks, Chunk),
			file_server_receiver(FilePath, Chunks);
		{getChunk, Index} ->
			whereis(dr) ! {chunkPart, Index, list:nth(Index, Chunks)},
			file_server_receiver(FilePath, Chunks);
		{q} ->
			Chunks = [];
			%file:del_dir(FilePath, [recursive, force])
	end.

% requests file information from the Directory Service (DirUAL) on File
% then requests file parts from the locations retrieved from Dir Service
% then combines the file and saves to downloads folder
get(DirUAL, File) ->
	whereis(dr) ! {g, DirUAL, File}.
	% CODE THIS
	% Check if downloads (directory/downloads) exists; if not, create it
	% Takes file name as input
	% Find each file part in individual servers
	% Combines them and places in downloads folder

% gives Directory Service (DirUAL) the name/contents of File to create
create(DirUAL, File) ->
	whereis(dr) ! {c, DirUAL, File}.


message_servers(Message, Files, Index) ->
	pass.
	

while(false, FileStuff, Pos, Fad, Step, Index, Len, FName, FSS) -> 
	Booler = Index-1 < length(FSS),
	if 
		Booler == true ->
			FName = string:join("/servers/fs",Index),
			FName = string:join(FName, "/"),
			FName = string:join(FName, Fad),
			FName = string:join(FName, "_"),
			FName = string:join(FName, Step/64),
			FName = string:join(FName, ".txt"),
			file:write_file(FName, substr(FileStuff, Step-64, Step - (Step-64))),
			list:nth(Index-1, FSS) ! {addChunk, substr(FileStuff, Step-64, Step - (Step-64))};
		true ->
			Index = 1,
			FName = string:join("/servers/fs",Index),
			FName = string:join(FName, "/"),
			FName = string:join(FName, Fad),
			FName = string:join(FName, "_"),
			FName = string:join(FName, Step/64),
			FName = string:join(FName, ".txt"),
			file:write_file(FName, substr(FileStuff, Step-64, Step - (Step-64))),
			list:nth(Index-1, FSS) ! {addChunk, substr(FileStuff, Step-64, Step - (Step-64))}
	end;
while(Checker, FileStuff, Pos, Fad, Step, Index, Len, FName, FSS) ->
	Booler = filelib:is_dir(FName),
	if 
		Booler == true ->
			FName = string:join("/servers/fs",Index),
			FName = string:join(FName, "/"),
			FName = string:join(FName, Fad),
			FName = string:join(FName, "_"),
			FName = string:join(FName, Step/64),
			FName = string:join(FName, ".txt"),
			file:write_file(FName, substr(FileStuff, Step, 64)),
			list:nth(Index-1, FSS) ! {addChunk, substr(FileStuff, Step-64, Step - (Step-64))},
			while(Step+64 < Len+1, FileStuff, Pos, Fad, Step+1, Index+1, Len, string:concat("/servers/fs",Index+1), FSS);
		true ->
			Index = 1,
			FName = string:join("/servers/fs",Index),
			FName = string:join(FName, "/"),
			FName = string:join(FName, Fad),
			FName = string:join(FName, "_"),
			FName = string:join(FName, Step/64),
			FName = string:join(FName, ".txt"),
			file:write_file(FName, [substr(FileStuff, Step, 64)]),
			list:nth(Index-1, FSS) ! {addChunk, substr(FileStuff, Step-64, Step - (Step-64))},
			while(Step+64 < Len+1, FileStuff, Pos, Fad, Step+1, Index+1, Len, string:concat("/servers/fs",Index+1), FSS)
	end.

	% CODE THIS
	% Takes file from input folder.
	% Split file into file parts and send them through the file servers in rotation

% sends shutdown message to the Directory Service (DirUAL)
quit(DirUAL) ->
	whereis(dr) ! {q}.
	% CODE THIS