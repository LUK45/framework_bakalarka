-module(serviceRegisterMonitor).

-compile(export_all).



%%% monitor pre service serviceRegister

%% spawne monitor, referenciu vratim service registru
start(SrID) ->
	{MonitorPid, MonitorRef} = erlang:spawn_monitor(?MODULE, init, [SrID]),
	io:format("serviceRegisterMonitor:  ref for sr: ~p monitorujem ~p ~n",[MonitorRef,MonitorPid]),
	MonitorRef.

init(SrID) -> 
	MonitorRef = monitor(process,SrID),
	io:format("serviceRegisterMonitor: my ref ~p monitorujem ~p moje id ~p~n",[MonitorRef,SrID, self()]),
	loop(MonitorRef).

loop(MonitorRef) ->
	receive

		%% padol master SR
		{'DOWN', MonitorRef, process, sr, Why} ->
			io:format("serviceRegisterMonitor: padol sr master dovod ~p~n",[Why]),
			lbsr ! {self(), srMstDown},
			register(sr, _Pid = spawn(fun() -> serviceRegister:start(master,null) end));


		%% mirror ukonceny 
		{'DOWN', MonitorRef, process, SrID, normal} -> loop(MonitorRef);


		%%padol mirror 
		{'DOWN', MonitorRef, process, SrID, Why} -> loop(MonitorRef)
	end.	





	
