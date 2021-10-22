-module(main).
-import(util,[readFile/1,get_all_lines/1,saveFile/2]).
-import(lists,[append/2]). 
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
	DS = spawn(dir_service_receiver([])).
	% CODE THIS
	% Create new directory service as actor
	% Use spawn in order to run stuff in the background.


% starts a file server with the UAL of the Directory Service
start_file_server(DirUAL) ->
	FS = spawn(file_server_receiver()),
	DS ! {addFile, FS}.
	%FS = spawn(util, )
	% CODE THIS
	% Create folder in server
	% name is taken as input 

dir_service_receiver(LS) ->
	FSList = LS,
	receive
		{addFile, FS} ->
			append(FSList, FS),
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

file_server_receiver() ->
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
	Step = 0.
	%while(substrn(FileStuff,step,64)) ->




	
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