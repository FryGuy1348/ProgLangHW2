-module(main).
-import(util,[readFile/1,get_all_lines/1,saveFile/2]).
-import(lists,[append/2]). 
-import(string,[substr/3]). 
-import(string,[len/1]). 
-import(string,[concat/2]).
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
	Pid = spawn(node(), fun() -> dir_service_receiver([], 1, dict:new()) end),
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

dir_service_receiver(LS, FNum, FDict) ->
	FSList = LS,
	receive
		{addFile} ->
			F0 = "servers/fs",
			FX = integer_to_list(FNum),
			%io:fwrite("Debugger0~n"),
			%io:fwrite("~p1~n", [FX]),
			F1 = string:concat(F0, FX),
			%io:fwrite("~p2~n", [F1]),
			%FN = integer_to_list(length(FSList) + 1),
			%io:fwrite("Debugger0~n"),
			%io:fwrite("~p1~n", [FN]),
			F1 = string:concat(F0, FX),
			FS = spawn(fun() -> file_server_receiver(F1, dict:new()) end),
			
			FSList1 = append(FSList, [pid_to_list(FS)]),

			%io:fwrite("Debugger1~n"),

			io:fwrite("~p~n",[file:make_dir(F1)]),
			%io:fwrite("Debugger4~n"),
			
			%file:make_dir(F1),
			dir_service_receiver(FSList1, FNum+1, FDict);
		%Perform Get operations
		{get, Arg2} ->
			Pid2 = spawn(node(), fun() -> fullFile("") end),
			register(wa, Pid2),
			Pid3 = spawn(node(),fun() ->file_getter(Arg2, 1, list_to_pid(lists:nth(1, FSList)), FSList, FDict) end),
			register(de,Pid3),
			whereis(de) ! {startProcess, Arg2, 1, list_to_pid(lists:nth(1, FSList)), FSList, FDict},
			%Spawn file_getter as a process, obtain pid to send to other functions
			%Go through each file server, 
			%Set index at 1
			%Match filename with index to find key
			%If in map, addd and move onto next file server
			%else end get and return file
			dir_service_receiver(FSList, FNum, FDict);
		%Perform Create operations (Arg1 = DirUal, Arg2 = File)
		{create, Arg2} ->
			FileStuff = readFile(string:concat("input/",Arg2)),
			Pos = string:chr(Arg2, $.),
			io:fwrite("~p4~n", [Pos]),
			%Get file name separate from .txt
			Fad = string:substr(Arg2, 1, Pos-1),
			io:fwrite("~p5~n", [Fad]),

			Index = 1,
			InV = integer_to_list(Index),
			Len = len(FileStuff),
			FName = string:concat("servers/fs",InV),
			%Go through while loop and split up chunks among file servers
			while(1 < Len+1, FileStuff, Fad, 65, 1, Len, FName, FSList,1),
			dir_service_receiver(FSList, FNum, FDict);


		{addPart, ID, Part, Index} ->
			list_to_pid(lists:nth(Index, FSList)) ! {addChunk, ID, Part},
			dict:store(ID, Index, FDict),
			dir_service_receiver(FSList, FNum, FDict);
		%Send Quit command to all file servers
		{q} ->
			destroy_servers(FSList, 1, FNum)
	end.

file_server_receiver(FilePath, Chunks) ->
	receive
		{addChunk, Fname, Chunk} ->
			dict:store(Fname, Chunk, Chunks),
			%Chunks = append(Chunks, Chunk),
			file_server_receiver(FilePath, Chunks);
			%Pass caller (function) in message
		{getChunk, Key, Caller} ->
			Caller ! {chunkPart, dict:fetch(Key,Chunks)},
			%whereis(dr) ! {chunkPart, Index, lists:nth(Index, Chunks)},
			file_server_receiver(FilePath, Chunks);
		{isChunk, Key, Caller} ->
			Caller ! {isTrue, dict:find(Key, Chunks)},
			file_server_receiver(FilePath, Chunks);
		{q} ->
			file:del_dir_r(FilePath),
			Chunks = dict:new()
			%file:del_dir(FilePath, [recursive, force])
	end.

destroy_servers(FSList, Index, FNum) ->
	Booler = Index < FNum,
	io:fwrite("~p Ind~n", [Index]),
	io:fwrite("~p Num~n", [FNum]),
	case Booler of 
		true ->
			list_to_pid(lists:nth(Index, FSList)) ! {q},
			destroy_servers(FSList, Index+1, FNum);
		false ->
			pass
	end.

% requests file information from the Directory Service (DirUAL) on File
% then requests file parts from the locations retrieved from Dir Service
% then combines the file and saves to downloads folder
get(DirUAL, File) ->
	whereis(dr) ! {get, File}.
	% CODE THIS
	% Check if downloads (directory/downloads) exists; if not, create it
	% Takes file name as input
	% Find each file part in individual servers
	% Combines them and places in downloads folder

fullFile(Content) ->
	receive
		{addContent, NewContent} -> fullFile(string:concat(Content, NewContent));
		{getContent, Caller} -> Caller ! {getString, Content},
			fullFile("")
	end.

%write receive for Is and Get
%make separate object to store string, receive at end
file_getter(FileName, Index, FS, FSList, FDict) ->
	receive
		{startProcess, FileName, Index, FS, FSList, FDict} ->
			Str = string:concat(FileName, "_"),
			Str = string:join(Str, Index),
			FS ! {isChunk, Str},
			file_getter(FileName, Index, FS, FSList, FDict);
		{getString, Val} -> 
			Str1 = saveFile("downloads/", FileName),
			file:write_file(Str1, Val);
		{getPart, Part} -> 
			whereis(wa) ! {addContent, Part},
			file_getter(FileName, Index+1, list_to_pid(lists:nth(Index rem length(FSList), FSList)), FSList, FDict);
		{isTrue, Booler} ->
			case Booler of 
				true ->
					Str = string:concat(FileName, "_"),
					Str = string:join(Str, Index),
					FS ! {getChunk, Str};
					%FS found by getting remainder of current Index (file part num) / length of File Server list
					%Str2 = string:join(Str2, file_getter(FileName, Index+1, list:nth(Index rem length(FSList), FSList), FSList))
				false ->
					whereis(wa) ! {getContent, whereis(de)}	
			end,
			file_getter(FileName, Index, FS, FSList, FDict)
	end.


% gives Directory Service (DirUAL) the name/contents of File to create
create(DirUAL, File) ->
	whereis(dr) ! {create, File}.

%Loop to create new file parts from input file
%True - Step < # of characters, False - Greater/Equal
while(false, FileStuff, Fad, Step, Index, Len, FName, FSS, PNum) -> 
	%io:fwrite("~pInd~n", [Index]),
	%io:fwrite("~p Step~n", [Step]),
	%io:fwrite("~p Len~n", [Len]),
	Booler = filelib:is_dir(FName),
	case Booler of 
		true ->
			InV = integer_to_list(Index),
			FName0 = string:concat("servers/fs",InV),
			FName1 = string:concat(FName0, "/"),
			FName2 = string:concat(FName1, Fad),
			FName3 = string:concat(FName2, "_"),
			Sv = integer_to_list(PNum),
			FName4 = string:concat(FName3, Sv),
			FName5 = string:concat(FName4, ".txt"),
			util:saveFile(FName5, substr(FileStuff, Step-64, Step - (Step-64))),
			whereis(dr) ! {addPart, string:concat(string:concat(Fad, "_"), Sv), substr(FileStuff, Step-64, Step - (Step-64)), Index};
		false ->
			FName0 = "servers/fs1",
			FName1 = string:concat(FName0, "/"),
			FName2 = string:concat(FName1, Fad),
			FName3 = string:concat(FName2, "_"),
			Sv = integer_to_list(PNum),
			FName4 = string:concat(FName3, Sv),
			FName5 = string:concat(FName4, ".txt"),
			util:saveFile(FName5, substr(FileStuff, Step-64, Step - (Step-64))),
			whereis(dr) ! {addPart, string:concat(string:concat(Fad, "_"), Sv), substr(FileStuff, Step-64, Step - (Step-64)), 1}
	end;
while(true, FileStuff, Fad, Step, Index, Len, FName, FSS, PNum) ->
	Booler = filelib:is_dir(FName),
	%io:fwrite("~pF~n", [FName]),
	%io:fwrite("~pInd~n", [Index]),
	%io:fwrite("~p Step~n", [Step]),
	%io:fwrite("~p Len~n", [Len]),
	case Booler of 
		true ->
			InV = integer_to_list(Index),
			FName0 = string:concat("servers/fs",InV),
			FName1 = string:concat(FName0, "/"),
			FName2 = string:concat(FName1, Fad),
			FName3 = string:concat(FName2, "_"),
			Sv = integer_to_list(PNum),
			FName4 = string:concat(FName3, Sv),
			FName5 = string:concat(FName4, ".txt"),
			util:saveFile(FName5, substr(FileStuff, Step-64, 64)),
			whereis(dr) ! {addPart, string:concat(string:concat(Fad, "_"), Sv), substr(FileStuff, Step - 64, Step - (Step-64)), Index},
			while(Step+64 < Len, FileStuff, Fad, Step+64, Index+1, Len, string:concat("servers/fs",integer_to_list(Index+1)), FSS, PNum+1);
		false ->
			FName0 = "servers/fs1",
			FName1 = string:concat(FName0, "/"),
			FName2 = string:concat(FName1, Fad),
			FName3 = string:concat(FName2, "_"),
			Sv = integer_to_list(PNum),
			FName4 = string:concat(FName3, Sv),
			FName5 = string:concat(FName4, ".txt"),
			util:saveFile(FName5, substr(FileStuff, Step-64, 64)),
			whereis(dr) ! {addPart, string:concat(string:concat(Fad, "_"), Sv), substr(FileStuff, Step-64, Step - (Step-64)), 1},
			while(Step+64 < Len, FileStuff, Fad, Step+64, 2, Len, "servers/fs2", FSS, PNum+1)
	end.

	% CODE THIS
	% Takes file from input folder.
	% Split file into file parts and send them through the file servers in rotation

% sends shutdown message to the Directory Service (DirUAL)
quit(DirUAL) ->
	whereis(dr) ! {q}.
	% CODE THIS