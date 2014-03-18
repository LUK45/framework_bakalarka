-module(serviceRegister).
%% gen_server_mini_template
-behaviour(gen_server).

-export([start_link/1,find_LbSs/3,addService/2,giveSRList/1,newDict/2,
		newSrList/2,giveServicesDict/1,showSRList/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
terminate/2, code_change/3]).


start_link(Dict) -> gen_server:start_link(?MODULE, Dict, []).


init(St) -> 
	io:format("serviceRegister~p: ~n~p~n",[self(), St]),
	process_flag(trap_exit, true),
	Mode = dict:fetch(mode, St),
	if
		Mode =:= master ->
			
			case whereis(lbsr) of

				undefined ->
					io:format("serviceRegister:~p false reg~n",[self()]),
					SRL = queue:in(self(), queue:new());

				_Pid  ->
					io:format("serviceRegister:~p true reg~n",[self()]),
					SRL = loadBalancerSR:giveSRList(lbsr),
					io:format("sr~p: srlist: ~p~n",[self(), SRL])
											
			end,
			St2 = dict:store(srList, SRL, St);
		true -> 
			St2 = St	
	end,
	io:format("serviceRegister:~p after reg~n",[self()]),
	

	
	Lbsr = whereis(lbsr),
	Sr = whereis(sr),
	case {Mode,Lbsr,Sr} of

	    {normal, _, undefined} ->
		    io:format("serviceRegister:~p mode normal, sr down~n",[self()]), %%% toto by enmalo nastat -> doriesit!!!
	    	Dict2 = noDict;
	    
	    {normal, _, _Pi} -> 
	    io:format("sr~p: druha~n",[self()]),
	    	Dict2 = loadBalancerSR:giveServicesDict(sr); 
	    
	    
	    {master, undefined, _} ->
	    io:format("sr~p: tretia~n",[self()]),
	    	Dict2 = dict:new();
	    
	    {master, _P, _} ->
	    io:format("sr~p: stvrta~n",[self()]),
	    	Dict = loadBalancerSR:giveServicesDict(lbsr),
	    	io:format("sr~p: dostal som dict ~p~n",[self(), Dict]),
	    	if
	    		Dict =:= noDict ->

	    			Dict2 = dict:new();
	    		true -> Dict2 = Dict	
	    	end
	    	
	end,   

	State = dict:store(dict, Dict2, St2),
	if
		Mode =:= master ->
			io:format("sr~p: som master registrujem sa~n",[self()]),
			register(sr, self());
		true ->	
			io:format("sr~p: nie som master neregistrujem sa~n",[self()])
	end,

	
	io:format("serviceRegister~p: ~n~p~n",[self(), State]),
	{ok, State}.

addService(Pid, ServiceId) -> gen_server:cast(Pid, {addService,ServiceId}).

giveSRList(Pid) -> gen_server:call(Pid,{giveSRList}).	

newSrList(Pid,SRL) -> gen_server:cast(Pid, {newSrList,SRL}).

newDict(Pid, Dict) -> gen_server:cast(Pid, {newDict, Dict}).


showSRList(Pid) -> gen_server:cast(Pid, {showSRList}).




find_LbSs(Pid, ServiceId, WorkerPid) -> gen_server:call(Pid, {find_LbSs, ServiceId, WorkerPid}).

giveServicesDict(Pid) -> gen_server:call(Pid,{giveServicesDict}).



%% gen_server callbacks.........................................................................................

handle_call({giveServicesDict} , _From, State) ->
	io:format("sr: ~p givingdist~n",[self()]),	
	case dict:is_key(dict,State) of
		true ->
		Reply = dict:fetch(dict, State),
		io:format("sr: ~p givingdist~p~n",[self(),Reply]);
			
		false ->
			Reply = noDict	,
		io:format("sr: ~p givingdist~p~n",[self(),Reply])
	end,
	
	{reply,Reply, State};



handle_call({giveSRList}, _From, State) ->
	Reply = dict:fetch(srList,State),
	{reply, Reply, State};

handle_call({find_LbSs, ServiceId, _WorkerPid}, _From, State) -> 
	Reply = dict:fetch(ServiceId, dict:fetch(dict,State)),
	io:format("serviceRegister~p: posielam ~p ako lbss pre ~p~n",[self(), Reply, ServiceId]),
	{reply, Reply, State};


handle_call(_Request, _From, State) -> {reply, reply, State}.

handle_cast({addService, ServiceId}, State) ->
	Mode = dict:fetch(mode,State),
	if
		 Mode =:= master ->
			Dict = dict:fetch(dict, State),
			Name = string:concat("lbss", erlang:atom_to_list(ServiceId)),
	    	LbSsState = dict:store(serviceId, ServiceId, dict:new()),
			{ok, Pid} = supervisor:start_child(rootLb, {Name,{lbSsSupervisor, start_link, [LbSsState]}, permanent, 1000, supervisor, [lbSsSupervisor]} ),
			[{_Id, Child, _Type, _Modules}] = supervisor:which_children(Pid),
			Dict1 = dict:store(ServiceId, Child, Dict),
			informSRList(Dict1, dict:fetch(srList,State)),
			State1 = dict:erase(dict,State),
			State2 = dict:store(dict,Dict1,State1);

		true ->
			io:format("sr~p: nie som master, nemozem pridat sluzbu~n",[self()]),
			State2 = State	
	end,
	{noreply, State2};

handle_cast({showSRList}, State) ->
	io:format("lbsr~p: srlist: ~p~n",[self(), dict:fetch(srList, State)]),
	{noreply, State};

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
terminate(normal, _State) -> io:format("sr~p: terminating reason ~p~n",[self(), normal]), ok;
terminate(Reason, State) -> 
	io:format("sr~p: terminating reason ~p~n",[self(), Reason]),
	Mode = dict:fetch(mode, State),
	if
		Mode =:= master ->
			loadBalancerSR:srDown(lbsr,master,self());
		true ->
			loadBalancerSR:srDown(lbsr,normal,self())
	end,
		 ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.


% other ........................



informSRList(Dict, SRL) ->
	L = queue:to_list(SRL),
	lists:foreach(
		fun(Pid) -> 
			if
				Pid =:= self() ->
					ok;
				true ->	
					serviceRegister:newDict(Pid,Dict)
	 		end
	 	end
	 , L).	