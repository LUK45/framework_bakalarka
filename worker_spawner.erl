-module(worker_spawner).
%% gen_server_mini_template
-behaviour(gen_server).
-export([start_link/1,spawnWorker/2]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
terminate/2, code_change/3]).

start_link(State) -> gen_server:start_link( ?MODULE, State, []).

init(State) -> 
	io:format("worker_spawner:~p~n",[self()]),
	{ok, State}.

spawnWorker(Pid,Name) -> gen_server:cast(Pid, {spawnWorker,Name}).

handle_call(_Request, _From, State) -> {reply, reply, State}.

handle_cast({spawnWorker,Name},State) ->
	{ok, Wpid} = worker:start_link(ar),
	register(Name,Wpid),
	State2 = dict:erase(myWorker,State),
	State3 = dict:store(myWorker,Name,State2),
	{noreply,State3};

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, Extra) -> {ok, State}.
