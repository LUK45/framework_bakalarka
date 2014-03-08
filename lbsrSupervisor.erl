-module(lbsrSupervisor).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link(?MODULE, []).

init([]) ->
    {ok, {{one_for_one, 3, 60},
         [{loadBalancerSR,
           {loadBalancerSR, start_link, []},
           temporary, 1000, worker, [loadBalancerSR]}
         ]}}.
