-module(serviceRegisterMonitor).

-compile(export_all).



%%% monitor pre service serviceRegister

%% spawne monitor, referenciu vratim service registru
start(SrID) ->
	{MonitorPid, MonitorRef} = erlang:spawn_monitor(?MODULE, init, [SrID]),
	io:format("serviceRegisterMonitor:  ref for sr: ~p monitorujem ~p ~n",[MonitorRef,MonitorPid]),
	MonitorRef.

init(SrID) -> 
	Ref = monitor(process,SrID),
	io:format("serviceRegisterMonitor: my ref ~p monitorujem ~p moje id ~p~n",[Ref,SrID, self()]),
	loop(Ref).

loop(Ref) ->
	Master = {sr,node()},
	receive

		%% padol master SR
		{'DOWN',Ref, process, Master, Why} ->
			io:format("serviceRegisterMonitor: padol sr master dovod ~p~n",[Why]),
			lbsr ! {self(), srMstDown},
			register(sr, _Pid = spawn(fun() -> serviceRegister:start(master,null) end));


		%% mirror ukonceny 
		{'DOWN',Ref, process, SrID, normal} -> 
			io:format("serviceRegisterMonitor: padol sr  ~p dovod ~p~n",[SrID,normal]),
			loop(Ref);


		%%padol mirror 
		{'DOWN',Ref, process, SrID, Why} -> 
			io:format("serviceRegisterMonitor: padol sr  ~p dovod ~p~n",[SrID,Why]),
			loop(Ref);

		Any -> Any
	end.	





	
