
-module(loadBalancerSR).
%% gen_server_mini_template
-behaviour(gen_server).

-export([start_link/1, find_LbSs/3, addMirror/1, giveSRList/1, giveServicesDict/1]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
terminate/2, code_change/3]).



start_link(State) -> gen_server:start_link(?MODULE, State, []).


init(State) -> 
	io:format("lbsr~p: init ~p ~n",[self(),State]),

	SRL = dict:fetch(srList, State),
	if
		SRL =:= null ->
			SRL2 = serviceRegister:giveSRList(sr);
		true ->
			SRL2 = SRL
	end,

	%pridat onitor
	State2 = dict:erase(srList, State),
	State3 = dict:store(srList, SRL2,State2),
	io:format("lbsr~p: my state: ~p~n",[self(), State3]),
	{ok, State3}.


addMirror(Pid) -> gen_server:cast(Pid, {addMirror}).

find_LbSs(Pid,ServiceId,WorkerPid) -> 
	io:format("lbsr~p: findlbss ~p~n",[self(), ServiceId]),
	gen_server:call(Pid, {find_LbSs, ServiceId,WorkerPid}).

giveSRList(Pid) -> gen_server:call(Pid, {giveSRList}).

giveServicesDict(Pid) -> gen_server:call(Pid,{giveServicesDict}).



%% gen_server callbacks.........................................................................................

handle_call({giveServicesDict} , _From, State) ->
	SRList = getSRListFromState(srList,State),
	{SRpid,SRList2} = loadBalancerRoundRobin:selectServer(SRList),
	State1= dict:erase(srList,State),
	State2 = dict:store(srList,SRList2,State1),	
	Reply = serviceRegister:giveServicesDict(SRpid),
	{reply,Reply, State2};


handle_call({giveSRList}, From, State) ->
	SRL = dict:fetch(srList,State),
	case lists:member(From,SRL) of
				true ->
					io:format("loadbalancerSR~p: ~p uz bol v liste, nepridavam~n",[self(), From]),
					SRL2 = SRL;
				false ->
					io:format("loadbalancerSR~p: ~p nebol v liste, pridavam~n",[self(),From]),
					SRL2 = SRL ++ [From]			
	end,
	Reply = SRL2,
	State1= dict:erase(srList,State),
	State2 = dict:store(srList,SRL2,State1),	
	{reply, Reply, State2};


handle_call({find_LbSs,ServiceId,WorkerPid} , _From, State) ->
	%io:format("lbsr: handle~n"), 
	SRList = getSRListFromState(srList,State),
	%io:format(";lbsr ~p~n",[SRList]),
	{SRpid,SRList2} = loadBalancerRoundRobin:selectServer(SRList),
	%io:format("lbsr~p: ~p~n",[self(),SRpid]),
	%State2 = updateStateSRList(srList, fun(V) -> V=SRList2 end, State),
	State1= dict:erase(srList,State),
	State2 = dict:store(srList,SRList2,State1),	
	Reply = serviceRegister:find_LbSs(SRpid,ServiceId,WorkerPid),
	{reply,Reply, State2};


handle_call(_Request, _From, State) -> {reply, reply,State}.



handle_cast({addMirror}, State) ->

	SRList = getSRListFromState(srList,State),
	{SRpid,SRList2} = loadBalancerRoundRobin:selectServer(SRList),
	Dict= serviceRegister:giveServicesDict(SRpid),

	SRState = dict:store(mode, normal, dict:new()),
	SRState2 = dict:store(dict, Dict,SRState),
	SRState3 = dict:store(srList, newMirror, SRState2),
	{ok, NewSRPid} = serviceRegister:start_link(SRState3),

	SRList3 = SRList2 ++ [NewSRPid],
	State1= dict:erase(srList,State),
	State2 = dict:store(srList,SRList3,State1),	

	informSRList(SRList3),

	{noreply, State2};	


handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, Extra) -> {ok, State}.

%% other .................................................................................

getSRListFromState(Key, Dict) ->
	SRList = dict:fetch(Key, Dict),
	SRList.	

updateStateSRList(Key,Fun,Dict) ->
	Dict2  = dict:update(Key, Fun, Dict),
	Dict2.

informSRList(SRL) -> 
	lists:foreach(fun(Pid) -> serviceRegister:newSrList(Pid,SRL) end, SRL).