-module(loadBalancerBehaviour).

-export([behaviour_info/1]).

behaviour_info(callbacks) ->
	[{selectServer,1}].