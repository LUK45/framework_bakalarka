-module(initModule).

-compile(export_all).



%%%% modul inti -> spusta na zaciatku vsetko ptorebne 


%%% nastartuje komponenty pri prvom zapnuti systemu
first_start(Ws_name, Session) -> 
io:format("===========================================================~ninitModule: nastartovany , moje pid je ~p~n", [self()]),

	%%% cache handler start
	%register(Ch, Ch_pid = spawn(fun() -> cache_handler:start() end)),
	

	%% service registrer start v mode master, dict null
	%register(SrMst, SrMst_pid = spawn(fun() -> serviceRegister:start(master,null) end)),
	Dict = dict:store(mode, master, dict:new()),
	{ok, Pid} = serviceRegisterSupervisor:start_link(Dict),
	register(srsup, Pid),
	io:format("init: pid = ~p aaa ~p ~n",[Pid,supervisor:which_children(Pid)]),


	%register(SrMst, SrMst_pid = spawn(fun() -> serviceRegister:start(master,Dict,[self()]) end)),

	%{ok, SrMst_pid} = serviceRegister:start_link(D3),
	%register(SrMst,SrMst_pid),


%% load balancer pre service regisre start
	{ok, Pid2} = lbsrSupervisor:start_link(),
	register(lbsrsup, Pid2),




%%% nastartuje worker spawnera pri novom requeste
%start_worker_spawner(Ws_name,Session) ->
%	Lp = Lbsr_pid,
%	Cp = Ch_pid,

	WState = dict:store(myWorker, null,dict:new()),
	{ok,Ws_pid} = worker_spawner:start_link(WState),
	register(Ws_name,Ws_pid).

	%register(EH , _EH_pid = spawn(fun() -> errorHandler:start(Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SrList) end)).








