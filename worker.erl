-module(worker).
-behaviour(gen_server).

-export([init/1,handle_call/3, handle_cast/2, handle_info/2, terminate/2, 
		code_change/3]).

-export([start_link/1,find_LbSs/2]).


start_link(State) -> 
	gen_server:start_link(?MODULE, State, []).


find_LbSs(Pid,ServiceId) -> 
	io:format("worker ~p~n",[self()]),
	gen_server:cast(Pid, {find_LbSs, ServiceId}).



init(State) -> 
	io:format("worker~p: ~p~n",[self(),State]),
	%wtimer:start_link(self()),
	{ok, State}.


handle_call(_Request, _From, State) -> {reply, reply, State}.


handle_cast({find_LbSs, ServiceId},  State) -> 
	io:format("worker~p: vyziadam si od sr cez lbsr lbss pre service id ~p f**~p~n", [self(),ServiceId,State]),
	
	Reply = loadBalancerSR:find_LbSs(lbsr,ServiceId,self()),
	io:format("worker~p: reply = ~p~n",[self(),Reply]),
	{noreply,   State};	



handle_cast(_Msg, State) -> {noreply, State}.

handle_info(Msg, State) -> 
	io:format("worker: unknown message ~p som ~p~n",[Msg,self()]),		
	{noreply, State}.

terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, Extra) -> {ok, State}.