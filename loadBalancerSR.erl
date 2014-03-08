
-module(loadBalancerSR).
%% gen_server_mini_template
-behaviour(gen_server).

-export([start_link/0, find_LbSs/3, addMirror/1, giveSRList/1, giveServicesDict/1]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
terminate/2, code_change/3]).



start_link() -> gen_server:start_link(?MODULE, [], []).


init([]) -> 
	 

	io:format("lbsr~p: init  name ~n",[self()]),
	register(lbsr, self()),
	%SRL = dict:fetch(srList, State),
	
	SRL2 = serviceRegister:giveSRList(sr),
	
	%pridat onitor
	State = dict:store(srList, SRL2,dict:new()),
	io:format("lbsr~p: my state: ~p~n",[self(), State]),
	{ok, State}.


addMirror(Pid) -> gen_server:cast(Pid, {addMirror}).

find_LbSs(Pid,ServiceId,WorkerPid) -> 
	io:format("lbsr~p: findlbss ~p~n",[self(), ServiceId]),
	gen_server:call(Pid, {find_LbSs, ServiceId,WorkerPid}).

giveSRList(Pid) -> 
io:format("lllll~n"),
gen_server:call(Pid, {giveSRList}).

giveServicesDict(Pid) -> gen_server:call(Pid,{giveServicesDict}).



%% gen_server callbacks.........................................................................................

handle_call({giveServicesDict} , From, State) ->
	io:format("lbsr giving dict~n"),
	SRList = getSRListFromState(srList,State),
	if
		length(SRList) > 1 ->
			{SRpid,SRList2} = loadBalancerRoundRobin:selectServer(SRList),
			State1= dict:erase(srList,State),
			State2 = dict:store(srList,SRList2,State1),	
			Reply = serviceRegister:giveServicesDict(SRpid);
		true ->
			Reply = noDict,
			State2 = State	
	end,
	
	{reply,Reply, State2};


handle_call({giveSRList}, From, State) ->
	io:format("lbsr:~p giving srlist beg~n",[self()]),
	SRL = dict:fetch(srList,State),
	io:format("lbsr:~p giving srlist~n",[self()]),
	case lists:member(From,SRL) of
				true ->
					io:format("loadbalancerSR~p: ~p uz bol v liste, nepridavam~n",[self(), From]),
					SRL2 = SRL;
				false ->
					io:format("loadbalancerSR~p: ~p nebol v liste, pridavam~n",[self(),From]),
					SRL2 = SRL ++ [From]
					%informSRList(SRL2)
			
	end,
	io:format("lbsr:~p giving srlist~n",[self()]),
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

	%SRList = getSRListFromState(srList,State),
	%{SRpid,SRList2} = loadBalancerRoundRobin:selectServer(SRList),
	%Dict= serviceRegister:giveServicesDict(SRpid),

	SRState = dict:store(mode, normal, dict:new()),

	{ok, Pid} = serviceRegisterSupervisor:start_link(SRState),
	[{Id, Child, Type, Modules}] = supervisor:which_children(Pid),
	SRList = getSRListFromState(srList,State),
	SRL2 = SRList ++ [Child],
	St2 = dict:erase(srList, State),
	St3 = dict:store(srList, SRL2, St2),
	
	{noreply, St3};	


handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, Extra) -> {ok, State}.

%% other .................................................................................

getSRListFromState(Key, Dict) ->
	SRList = dict:fetch(Key, Dict),
	SRList.	



informSRList(SRL) -> 
	lists:foreach(fun(Pid) -> serviceRegister:newSrList(Pid,SRL) end, SRL).