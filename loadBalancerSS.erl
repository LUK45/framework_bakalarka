-module(loadBalancerSS).
%% gen_server_mini_template
-behaviour(gen_server).
-export([start_link/1]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
terminate/2, code_change/3]).


start_link(State) -> gen_server:start_link(?MODULE, State, []).

init(State) -> 
	io:format("loadBalancerSS~p: lbss for ~p~n",[self(),dict:fetch(serviceId,State)]),
	{ok, State}.


handle_call(_Request, _From, State) -> {reply, reply, State}.
handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, Extra) -> {ok, State}.
