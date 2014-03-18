-module(lbSsSupervisor).
-behaviour(supervisor).

-export([start_link/1]).
-export([init/1]).

start_link(Dict) ->
    supervisor:start_link(?MODULE, Dict).

init(Dict) ->
    {ok, {{one_for_one, 3, 60},
         [{loadBalancerSS,
           {loadBalancerSS, start_link, [Dict]},
           permanent, 1000, worker, [loadBalancerSS]}
         ]}}.
