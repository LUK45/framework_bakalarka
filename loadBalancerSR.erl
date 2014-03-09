
-module(loadBalancerSR).
%% gen_server_mini_template
-behaviour(gen_server).

-export([start_link/0, find_LbSs/3, addMirror/1, giveSRList/1, giveServicesDict/1, showSRList/1, srDown/3]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
terminate/2, code_change/3]).



start_link() -> gen_server:start_link(?MODULE, [], []).


init([]) -> 
	 

	io:format("lbsr~p: init  name ~n",[self()]),
	register(lbsr, self()),
	%SRL = dict:fetch(srList, State),
	process_flag(trap_exit, true),
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

showSRList(Pid) -> gen_server:cast(Pid, {showSRList}).

giveServicesDict(Pid) -> gen_server:call(Pid,{giveServicesDict}).

srDown(Pid,Mode,From) -> gen_server:cast(Pid, {srDown,Mode,From}).




%% gen_server callbacks.........................................................................................

handle_call({giveServicesDict} , From, State) ->
	io:format("lbsr giving dict~n"),
	SRList = getSRListFromState(srList,State),
	if
		length(SRList) > 1 ->
			{SRpid,SRList2} = loadBalancerRoundRobin:selectServer(SRList),
			io:format("lbsr~p: give dict ~p~n",[self(), SRpid]),
			State1= dict:erase(srList,State),
			State2 = dict:store(srList,SRList2,State1),	
			Reply = serviceRegister:giveServicesDict(SRpid),
			io:format("lbsr: ~p dict~p~n",[self(),Reply]);
		true ->
			Reply = noDict,
			State2 = State	
	end,
	
	{reply,Reply, State2};


handle_call({giveSRList}, From, State) ->
	io:format("lbsr:~p giving srlist beg~n",[self()]),
	SRL = dict:fetch(srList,State),
	io:format("lbsr:~p giving srlist~n",[self()]),
	case From of
		{Pid,Ref} ->
			From2 = Pid;
		{Pid} ->
			From2 = From	
	end,
	case lists:member(From2,SRL) of
				true ->
					io:format("loadbalancerSR~p: ~p, ~p uz bol v liste, nepridavam~n",[self(), From, From2]),
					SRL2 = SRL;
				false ->
					io:format("loadbalancerSR~p: ~p, ~p nebol v liste, pridavam~n",[self(),From, From2]),
					SRL2 = SRL ++ [From2]
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
	io:format("lbsr~p: selected sr is ~p~n",[self(), SRpid]),
	State1= dict:erase(srList,State),
	State2 = dict:store(srList,SRList2,State1),	
	Reply = serviceRegister:find_LbSs(SRpid,ServiceId,WorkerPid),
	{reply,Reply, State2};


handle_call(_Request, _From, State) -> {reply, reply,State}.


handle_cast({showSRList}, State) ->
	io:format("lbsr~p: srlist: ~p~n",[self(), dict:fetch(srList, State)]),
	{noreply, State};

handle_cast({srDown, Mode,From}, State) ->
	SRL = dict:fetch(srList, State),
	SRL2 = lists:delete(From, SRL),
	case Mode of
			master ->
				io:format("lbsr~p : master down, new srlist: ~p~n",[self(), SRL2]);
			normal ->
				io:format("lbsr~p : mirror down, new srlist: ~p~n",[self(), SRL2]),
				serviceRegister:newSrList(sr, SRL2)
							
	end,
	State2 = dict:erase(srList, State),
	State3 = dict:store(srList, SRL2, State2),
	{noreply, State3};

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
	serviceRegister:newSrList(sr,SRL2),
	{noreply, St3};	


handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.

%terminate(shutdown, S) -> io:format("lbsr:~p shutdown~n",[self()]), ok;
terminate(Reason, _State) -> io:format("lbsr~p: stopping reason ~p~n",[self(),Reason]), ok.
code_change(_OldVsn, State, Extra) -> {ok, State}.

%% other .................................................................................

getSRListFromState(Key, Dict) ->
	SRList = dict:fetch(Key, Dict),
	SRList.	



informSRList(SRL) -> 
	lists:foreach(fun(Pid) -> serviceRegister:newSrList(Pid,SRL) end, SRL).