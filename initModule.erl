-module(initModule).

-compile(export_all).



%%%% modul inti -> spusta na zaciatku vsetko ptorebne 


%%% nastartuje komponenty pri prvom zapnuti systemu
first_start(Lbsr, Ch, Ws_name, SrMst,  Session) -> 
io:format("===========================================================~ninitModule: nastartovany , moje pid je ~p~n", [self()]),

	%%% cache handler start
	register(Ch, Ch_pid = spawn(fun() -> cache_handler:start() end)),
	

	%% service registrer start v mode master, dict null
	%register(SrMst, SrMst_pid = spawn(fun() -> serviceRegister:start(master,null) end)),
	Dict = dict:store(mode, master, dict:new()),
	D2 = dict:store(dict, dict:new(), Dict),
	D3 = dict:store(srList, [], D2),



	%register(SrMst, SrMst_pid = spawn(fun() -> serviceRegister:start(master,Dict,[self()]) end)),

	{ok, SrMst_pid} = serviceRegister:start_link(D3),
	register(SrMst,SrMst_pid),


%% load balancer pre service regisre start
	SrList = [SrMst_pid],
	%Dict2=dict:new(),
	Dict3 = dict:store(srList,SrList,dict:new()),
	Dict4 = dict:store(myMonitor, null, Dict3),
	
	%register(Lbsr, Lbsr_pid = spawn(fun() -> loadBalancerSR:start(SrList) end)),

	{ok, Lbsr_pid} = loadBalancerSR:start_link(Dict4),
	register(Lbsr,Lbsr_pid),




%%% nastartuje worker spawnera pri novom requeste
%start_worker_spawner(Ws_name,Session) ->
	Lp = Lbsr_pid,
	Cp = Ch_pid,
	Ws_pid = spawn(fun() -> worker_spawner:start(Session, Ws_name,Lp, Cp) end).

	%register(EH , _EH_pid = spawn(fun() -> errorHandler:start(Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SrList) end)).








