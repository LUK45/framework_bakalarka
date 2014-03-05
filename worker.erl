-module(worker).
-compile(export_all).

%% modul worker, vytvori timer, dalej spracuvava request, kontaktuje cache handler, kontaktuje load balancer

start(Lbsr_pid, Ch_pid, Ws_Pid) ->
	io:format("worker: nastartovany worker moje pid je ~p a spawnol ma ws s pid: ~p~n", [MojePid = self(), Ws_Pid]),
	register(_Timer = timer, Timer_pid = spawn(fun() -> wtimer:start(MojePid,5000) end) ),
	loop(Lbsr_pid, Ch_pid, Timer_pid, Ws_Pid).



%%%%% akui finciu rrun -> ktora si vyziada potrebne serveri posle poziadavku posle poziadavku cach handlerovi aa z potom loop kde s auz len caka na odpovede


%%%% kontorlna funkcia
odozva() ->
	io:format("worker: som tu ~p ~n", self()).	

loop(Lbsr_pid, Ch_pid,Timer_pid, Ws_Pid) ->
	receive
		{Lbsr_pid, Resp} ->
			io:format("worker: response from ~p lbsr is ~p ~n", [Lbsr_pid, Resp]),
			loop(Lbsr_pid, Ch_pid,Timer_pid, Ws_Pid);
		{Ch_pid, RespC} ->
			io:format("worker: response from ~p ch is ~p ~n", [Ch_pid, RespC]),
			loop(Lbsr_pid, Ch_pid,Timer_pid, Ws_Pid);
		
			%%% timer -> funguje -> zatial nepotrbeujem
		%{Timer_pid, Sig} ->
		%	io:format("worker: end signal from ~p timer is ~p -> koncim~n", [Timer_pid, Sig]);				
		{Ws_Pid, Msg} ->
			io:format("worker: ws_pid: ~p  msg: ~p~n",[Ws_Pid,Msg]),
			Ws_Pid ! {self(),konci},
			io:format("worker: poslal som spravu na ~p  s ~p~n", [Ws_Pid, self()]),
			Lbsr_pid ! {self(), lbsr_request},
			Ch_pid ! {self(), ch_request},
			loop(Lbsr_pid, Ch_pid,Timer_pid, Ws_Pid);

		%%%% poziadavka pre lbsr aby mi dal sr	
		{findSR} ->
			io:format("worker: vyziadam si SR od load balanceraSR ~n"),
			lbsr ! {self(), findSR},
			loop(Lbsr_pid, Ch_pid,Timer_pid, Ws_Pid);
		%%% odpoved od lbsr s asdresou sr	
		{Lbsr_pid, findSR, ServiceRegisterPid} ->
			io:format("worker: haldany service register ma pid ~p adresu som dostal od Lbsr ~p ~n", [ ServiceRegisterPid,Lbsr_pid]),
			loop(Lbsr_pid, Ch_pid,Timer_pid, Ws_Pid);

		%%%% poziadavaka pre lbsr aby nasiel lbss pre konkretnu sluizbu
		{findLbSs, ServiceId} ->
			io:format("worker: vyziadam si od sr cez lbsr lbss pre service id ~p ~n", [ServiceId]),
			lbsr ! {self(), findLbSs, ServiceId},
			loop(Lbsr_pid, Ch_pid,Timer_pid, Ws_Pid);
		%%%% ocakavam odpoved s lbssPId	
		{ServiceRegisterPid, findLbSs, ServiceId, LbSsPid} ->
			io:format("worker: dostal som odpoved s LbSsPid ~p od Sr ~p pre serviceId ~p ~n",[LbSsPid,ServiceRegisterPid,ServiceId ]),
			loop(Lbsr_pid, Ch_pid,Timer_pid, Ws_Pid);

		Any -> 
			io:format("worker: z consoly ~p ~n", [Any]),
			loop(Lbsr_pid, Ch_pid,Timer_pid, Ws_Pid)
	end.			

		

