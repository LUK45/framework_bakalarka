-module(loadBalancerRoundRobin).


-compile(export_all).

%%%%% round robin -> pride list moznych serverov ktore sa tocia do kruhu
selectServer([H|T], State) ->
	io:format("loadBalancerRoundRobin: selectServer~n"),
	{H , T ++ [H], State};




%%% -1 ak nie je k dispozicii server
selectServer([], State) ->
	io:format("loadBalancerRoundRobin: selectServer -> no server ~n"),
	{-1, [], State}.

