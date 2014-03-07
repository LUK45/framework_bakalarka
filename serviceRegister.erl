-module(serviceRegister).
%% gen_server_mini_template
-behaviour(gen_server).

-export([start_link/1,find_LbSs/3,addService/2,giveSRList/1,newDict/2,
		newSrList/2,giveServicesDict/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
terminate/2, code_change/3]).


start_link(Dict) -> gen_server:start_link(?MODULE, Dict, []).


init(D2) -> 
	%D2 = dict:store(srList, [self()], Dict),
	io:format("serviceRegister~p: ~n~p~n",[self(), D2]),

	ServicesDict = dict:fetch(dict,D2),
	if
		ServicesDict =:= null ->
			io:format("serviceRegister~p: mam dict null~n",[self()]),
			ServicesDict2 = loadBalancerSR:giveServicesDict(lbsr);
		true ->
			io:format("serviceRegister~p: nemam dict null~n",[self()]),
			ServicesDict2 = ServicesDict
	end,

	D3 = dict:erase(dict,D2),
	D4 = dict:store(dict,ServicesDict2,D3),
    
    Mode = dict:fetch(mode, D4),
    SRL = dict:fetch(srList, D4),
    if
    	SRL =:= null ->
    		SRL2 = loadBalancerSR:giveSRList(lbsr);
    	SRL =:= newMirror ->
    		SRL2 = SRL;	
    	true ->
    		SRL2 = [self()]		
    end,

	
	D5 = dict:store(srList, SRL2, D4),

	io:format("serviceRegister~p: ~n~p~n",[self(), D5]),
	State = D5,
	{ok, State}.

addService(Pid, ServiceId) -> gen_server:cast(Pid, {addService,ServiceId}).

giveSRList(Pid) -> gen_server:call(Pid,{giveSRList}).	

newSrList(Pid,SRL) -> gen_server:cast(Pid, {newSrList,SRL}).

newDict(Pid, Dict) -> gen_server:cast(Pid, {newDict, Dict}).

find_LbSs(Pid, ServiceId, WorkerPid) -> gen_server:call(Pid, {find_LbSs, ServiceId, WorkerPid}).

giveServicesDict(Pid) -> gen_server:call(Pid,{giveServicesDict}).



%% gen_server callbacks.........................................................................................

handle_call({giveServicesDict} , _From, State) ->
	Reply = dict:fetch(dict, State),
	{reply,Reply, State};



handle_call({giveSRList}, _From, State) ->
	Reply = dict:fetch(srList,State),
	{reply, Reply, State};

handle_call({find_LbSs, ServiceId, WorkerPid}, _From, State) -> 
	Reply = dict:fetch(ServiceId, dict:fetch(dict,State)),
	io:format("serviceRegister~p: posielam ~p ako lbss pre ~p~n",[self(), Reply, ServiceId]),
	{reply, Reply, State};


handle_call(_Request, _From, State) -> {reply, reply, State}.

handle_cast({addService, ServiceId}, State) ->
	Mode = dict:fetch(mode,State),
	if
		 Mode =:= master ->
			Dict1 = addServiceId(dict:fetch(dict,State), ServiceId),
			%loadBalancerSR:newDict(lbsr,Dict1);
			informSRList(Dict1, dict:fetch(srList,State)),
			State1 = dict:erase(dict,State),
			State2 = dict:store(dict,Dict1,State1);

		true ->
			io:format("sr~p: nie som master, nemozem pridat sluzbu~n",[self()]),
			State2 = State	
	end,
	{noreply, State2};

handle_cast({newSrList,SRL}, State) ->
	State1= dict:erase(srList,State),
	State2 = dict:store(srList,SRL,State1),
	{noreply,State2};	
	


handle_cast({newDict, Dict}, State) ->
	State1= dict:erase(dict,State),
	State2 = dict:store(dict,Dict,State1),
	{noreply,State2};	

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, Extra) -> {ok, State}.


% other ........................

addServiceId(Dict, ServiceId) ->
	State = dict:store(serviceId, ServiceId, dict:new()),
	{ok,NewPid} = loadBalancerSS:start_link(State),
	Dict1 = dict:store(ServiceId, NewPid, Dict),
	Dict1.	

informSRList(Dict, SRL) ->
	lists:foreach(
		fun(Pid) -> 
			if
				Pid =:= self() ->
					ok;
				true ->	
					serviceRegister:newDict(Pid,Dict)
	 		end
	 	end
	 , SRL).	