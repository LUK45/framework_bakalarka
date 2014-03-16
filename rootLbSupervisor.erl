-module(rootLbSupervisor).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link(?MODULE, []).

init([]) ->
	register(rootLb, self()),
	%%register(rootLB,self()),
    {ok, {{one_for_one, 3, 60},
         [{lbsrSupervisor,
           {lbsrSupervisor, start_link, []},
           permanent, 1000, supervisor, [lbsrSupervisor]}	
         ]}}.

