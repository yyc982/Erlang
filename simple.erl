%%% 
%%% CS 610 Assignment 6
%%% a simple client server system in Erlang.
%%% Student: Yuechen Yang
%%% 11/29/2013
%%%
-module(simple).
-export([server/1, client/1, start/1]).

server (State) ->
	receive
		{request, Return_PID} ->
			%% dealing with requests from client
			io:format ("SERVER ~w: Client request received from ~w~n", [self(), Return_PID]),
			NewState = State + 1,
			Return_PID ! {hit_count, NewState}, 
			server (NewState);
		{server_owner, Owner_PID} ->
			%% interact with owner
			io:format("SERVER ~w: Owner query received from ~w ~n",[self(), Owner_PID]),
			Owner_PID ! {hit_count, State},				
			server (State);
		reset ->
			%% dealing with reset from owner
			io:format("SERVER ~w: Owner reset message received ~n", [self()]),
			server(0)	
	end.
	
client (Server_Address) ->
	Server_Address ! {request, self()},
	receive
		{hit_count, Number} ->
			io:format ("CLIENT ~w: Hit count was ~w~n", [self(), Number])
	end.

owner (Server_PID) ->
	Server_PID ! {server_owner, self()},
	receive
		%% check server State number
		{hit_count, Number} ->
			if 
				Number == 6 -> % if owner find server state reaches 6, send a reset message as well
					io:format ("OWNER ~w: Hit count is ~w send reset message....~n", [self(), Number]),
					Server_PID ! reset;
				true ->
					io:format ("OWNER ~w: Hit count is ~w~n", [self(), Number]) % normal case
			end		
	end.

spawn_n(N, Server_PID) -> 
	if
		N>0 ->
			%% initiate client process for N times 
			spawn (simple, client, [Server_PID]),
			%% keep owner maintaining
			owner (Server_PID),
			spawn_n(N-1, Server_PID);
		N == 0 ->
			io:format("Last client spawned. ~n")
	end.
	
	
	
start(Clients_Number) ->
	Server_PID = spawn (simple, server, [0]),
	%spawn(simple, client, [Server_PID]).					
	owner(Server_PID),

	spawn_n(Clients_Number, Server_PID).
	
						