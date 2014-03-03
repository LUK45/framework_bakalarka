-module(cache_handler).

-compile(export_all).

%%% modul cache handler -> obsluhuje cache pamet 



start() ->
io:format("cachehandler: nastartovany , moje pid je ~p~n", [self()]),
	loop().

loop() ->
	receive 
		{Pid, Msg} -> 
			io:format("Ch: received ~p from ~p~n",[Msg, Pid]),
			Pid ! {self(),response_lbsr},
			loop();

		%% kill signal
		{die, Pid, Reason} ->
			io:format("Ch: prijal som die signal od ~p dovod ~p~n", [Pid, Reason]),
			exit(Reason)	
	end.