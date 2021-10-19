-module(main).

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
	io:fwrite("~p~n", [file:make_dir("newdir")]).
	% CODE THIS
	% Create new directory/folder
	% Use name "localhost"


% starts a file server with the UAL of the Directory Service
start_file_server(DirUAL) ->
	pass.
	% CODE THIS
	% Create sub-directory under localhost folder (Create as actor, with UAL name)
	% name is taken as input 

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
	pass.
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