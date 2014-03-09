-module(loadBalancerRoundRobin).


-compile(export_all).

%%%%% round robin -> pride list moznych serverov ktore sa tocia do kruhu
selectServer(Q) ->
		io:format("loadBalancerRoundRobin: selectServer~n"),
		case queue:is_empty(Q) of
			false ->
				Result = queue:get(Q),
				NewQ = queue:in(Result,queue:drop(Q)),
				{Result,NewQ};
			true ->
				io:format("loadBalancerRoundRobin: selectServer -> no server ~n"),
				{-1}	

		end.

