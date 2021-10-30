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
	whereis(dr) ! {addFile}.
	% CODE THIS
	% Create folder in server
	% name is taken as input 

dir_service_receiver(LS) ->
	FSList = LS,
	receive
		{addFile} ->
			F1 = string:concat("servers/fs", length(FSList)+1),
			FS = spawn(fun() -> file_server_receiver(F1, []) end),
			
			FSList1 = append(FSList, FS),

			io:fwrite("Debugger1~n"),
			io:fwrite("~p~n", [F1]),			
			io:fwrite("~p~n",[file:make_dir("servers/fs")]),
			%io:fwrite("~p~n",[file:make_dir(string:concat("servers/fs", length(FSList)))]),
			io:fwrite("~p~n",[file:make_dir(string:join("servers/fs", length(FSList)))]),
			io:fwrite("Debugger4~n"),
			
			%file:make_dir(F1),
			dir_service_receiver(FSList1);
		%Perform Get operations
		{get, Arg1, Arg2} ->
			Pid2 = spawn(node(), fun() -> fullFile("") end),
			register(wa, Pid2),
			Pid3 = spawn(node(),fun() ->file_getter(Arg2, 1, list:nth(0, FSList), FSList) end),
			register(de,Pid3),
			whereis(de) ! {startProcess, Arg2, 1, list:nth(0, FSList), FSList},
			%Spawn file_getter as a process, obtain pid to send to other functions
			%string:concat(Str, file_getter(Arg2, 1, list:nth(0, FSList), FSList)),
			%Go through each file server, 
			%Set index at 1
			%Match filename with index to find key
			%If in map, addd and move onto next file server
			%else end get and return file
			dir_service_receiver(FSList);
		%Perform Create operations (Arg1 = DirUal, Arg2 = File)
		{create, Arg1, Arg2} ->
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
			destroy_servers(FSList, 0)
	end.

file_server_receiver(FilePath, Chunks) ->
	receive
		{addChunk, Fname, Chunk} ->
			maps:put(Fname, Chunk, Chunks),
			%Chunks = append(Chunks, Chunk),
			file_server_receiver(FilePath, Chunks);
			%Pass caller (function) in message
		{getChunk, Key, Caller} ->
			Caller ! {chunkPart, maps:get(Key,Chunks)},
			%whereis(dr) ! {chunkPart, Index, list:nth(Index, Chunks)},
			file_server_receiver(FilePath, Chunks);
		{isChunk, Key, Caller} ->
			Caller ! {isTrue, maps:find(Key, Chunks)},
			file_server_receiver(FilePath, Chunks);
		{q} ->
			pass
			%file:del_dir(FilePath, [recursive, force])
	end.

destroy_servers(FSList, Index) ->
	Booler = Index >= length(FSList),
	if Booler == true,
		pass;
		true ->
		list:nth(Index, FSList) ! {q},
		destroy_servers(FSList, Index+1)
	end.

% requests file information from the Directory Service (DirUAL) on File
% then requests file parts from the locations retrieved from Dir Service
% then combines the file and saves to downloads folder
get(DirUAL, File) ->
	whereis(dr) ! {get, DirUAL, File}.
	% CODE THIS
	% Check if downloads (directory/downloads) exists; if not, create it
	% Takes file name as input
	% Find each file part in individual servers
	% Combines them and places in downloads folder

fullFile(Content) ->
	receive
		{addContent, NewContent} -> fullFile(string:concat(Content, NewContent));
		{getContent, Caller, FileName} -> Caller ! {getString, Content},
			fullFile("")
	end.

%write receive for Is and Get
%make separate object to store string, receive at end
file_getter(FileName, Index, FS, FSList) ->
	receive
		{startProcess, FileName, Index, FS, FSList} ->
			Str = string:concat(FileName, "_"),
			Str = string:join(Str, Index),
			Booler = FS ! {isChunk, Str},
			file_getter(FileName, Index, FS, FSList);
		{getString, Val} -> 
			Str1 = saveFile("downloads/", FileName),
			file:write_file(Str1, Val);
		{getPart, Part} -> 
			whereis(wa) ! {addContent, Part},
			file_getter(FileName, Index+1, list:nth(Index rem length(FSList), FSList), FSList);
		{isTrue, Booler} ->
			if
			Booler == true ->
				Str = string:concat(FileName, "_"),
				Str = string:join(Str, Index),
				FS ! {getChunk, Str};
				%FS found by getting remainder of current Index (file part num) / length of File Server list
				%Str2 = string:join(Str2, file_getter(FileName, Index+1, list:nth(Index rem length(FSList), FSList), FSList))
			true ->
				whereis(wa) ! {getContent, whereis(de), FileName}	
			end,
			file_getter(FileName, Index, FS, FSList)
	end.


% gives Directory Service (DirUAL) the name/contents of File to create
create(DirUAL, File) ->
	whereis(dr) ! {create, DirUAL, File}.

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
			saveFile(FName, substr(FileStuff, Step-64, Step - (Step-64))),
			list:nth(Index-1, FSS) ! {addChunk, substr(FileStuff, Step-64, Step - (Step-64))};
		true ->
			Index = 1,
			FName = string:join("/servers/fs",Index),
			FName = string:join(FName, "/"),
			FName = string:join(FName, Fad),
			FName = string:join(FName, "_"),
			FName = string:join(FName, Step/64),
			FName = string:join(FName, ".txt"),
			saveFile(FName, substr(FileStuff, Step-64, Step - (Step-64))),
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
			saveFile(FName, substr(FileStuff, Step, 64)),
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
			saveFile(FName, [substr(FileStuff, Step, 64)]),
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