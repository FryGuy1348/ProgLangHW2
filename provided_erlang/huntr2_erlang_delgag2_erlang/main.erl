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

% starts a directory service (and fullFile actor for get operations)
start_dir_service() ->
	Pid = spawn(node(), fun() -> dir_service_receiver([], 1, dict:new()) end),
	register(dr, Pid),
	Pid2 = spawn(node(), fun() -> fullFile("") end),
	register(ff, Pid2).

% starts a file server with the UAL of the Directory Service
start_file_server(DirUAL) ->
	whereis(dr) ! {addFile}.

%Directory service actor
%LS - FileServer list
%FNum - Number of file servers / fs(FNum)
%FDict - Dictionary of file part names and file server it is contained in
dir_service_receiver(LS, FNum, FDict) ->
	FSList = LS,
	receive
		%Add fileserver to the File server list (LS), and create a new FS directory based on FNum (# of servers)
		{addFile} ->
			F0 = "servers/fs",
			FX = integer_to_list(FNum),
			F1 = string:concat(F0, FX),
			FS = spawn(fun() -> file_server_receiver(F1, dict:new()) end),
			
			FSList1 = append(FSList, [pid_to_list(FS)]),

			%Make directory, fwrite for testing
			io:fwrite("~p~n",[file:make_dir(F1)]),

			%Call directory service again to keep it going as a process
			dir_service_receiver(FSList1, FNum+1, FDict);

		%Perform Get operations (Filter directory to get only the necessary file parts and combine the parts)
		%(Arg2 = File)
		{get, Arg2} ->
			Pos = string:chr(Arg2, $.),
			Fad = string:substr(Arg2, 1, Pos-1),
			Matches = fun(K, _) -> string:slice(K, 0, string:length(K) - string:length(string:find(K, "_", trailing))) == Fad end,
			TempDict = dict:filter(Matches, FDict),
			FSize = dict:size(TempDict),
			%Actually go through file parts
			f_get(Fad, FSList, TempDict, FSize, 1),

			dir_service_receiver(FSList, FNum, FDict);

		%Perform Create operations (Arg2 = File)
		{create, Arg2} ->
			FileStuff = readFile(string:concat("input/",Arg2)),
			Pos = string:chr(Arg2, $.),

			%Get file name separate from .txt
			Fad = string:substr(Arg2, 1, Pos-1),

			Index = 1,
			InV = integer_to_list(Index),
			Len = len(FileStuff),
			FName = string:concat("servers/fs",InV),

			%Go through while loop and split up chunks among file servers
			while(1 < Len+1, FileStuff, Fad, 65, 1, Len, FName, FSList,1),
			dir_service_receiver(FSList, FNum, FDict);

		%Add entry to FileDictionary to keep track of where file part is, add chunk to relevant server
		{addPart, ID, Part, Index} ->
			list_to_pid(lists:nth(Index, FSList)) ! {addChunk, ID, Part},
			F1 = dict:store(ID, Index, FDict),
			dir_service_receiver(FSList, FNum, F1);

		%Send Quit command to all file servers
		{q} ->
			destroy_servers(FSList, 1, FNum)
	end.

%Actor for file server
%Chunks = dictionary of file parts
file_server_receiver(FilePath, Chunks) ->
	receive
		%Add file part to dictionary of file parts (Key == fileName_num, Value == Contents of file part)
		{addChunk, Fname, Chunk} ->
			C2 = dict:store(Fname, Chunk, Chunks),
			file_server_receiver(FilePath, C2);
		
		%Pass file part to fullFile actor (stores contents of files and then saves them in downloads)
		{getChunk, Key} ->
			V1 = dict:fetch(Key,Chunks),
			whereis(ff) ! {addContent, V1},
			file_server_receiver(FilePath, Chunks);

		%Destroy file server + directory
		{q} ->
			file:del_dir_r(FilePath)
		end.

%Send command to file servers to quit/destroy themselves
destroy_servers(FSList, Index, FNum) ->
	Booler = Index < FNum,
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
% Sends get command to directory service
get(DirUAL, File) ->
	whereis(dr) ! {get, File}.

%Stores full string until it is ready to be written to a file
fullFile(Content) ->
	receive
		{addContent, NewContent} -> timer:sleep(50),fullFile(string:concat(Content, NewContent));
		{getContent, FileName} -> timer:sleep(50),saveFile(FileName, Content), fullFile("")
	end.

%Get file parts from FDict and sends them to fullFile for compiling
%FName - filename without .txt
%FDIct - filtered dictionary
%FNum - number of file parts to look out for
%Index - current file part to get
f_get(FName, FSList, FDict, FNum, Index) ->
	timer:sleep(500),
	case Index < (FNum+1) of
		true ->
			S1 = string:concat(string:concat(FName, "_"), integer_to_list(Index)),
			FX = list_to_pid(lists:nth(dict:fetch(S1, FDict), FSList)),
			FX ! {getChunk, S1},
			f_get(FName, FSList, FDict, FNum, Index+1);
		false ->
			timer:sleep(50),
			whereis(ff) ! {getContent, string:concat("downloads/", string:concat(FName, ".txt"))}
	end.

% gives Directory Service (DirUAL) the name/contents of File to create
create(DirUAL, File) ->
	whereis(dr) ! {create, File}.

%Loop to create new file parts from input file
%True - Step < # of characters, False - Greater/Equal
while(false, FileStuff, Fad, Step, Index, Len, FName, FSS, PNum) -> 
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

% sends shutdown message to the Directory Service (DirUAL)
quit(DirUAL) ->
	whereis(dr) ! {q}.