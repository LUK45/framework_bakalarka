-module(rootSrSupervisor).

-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link(?MODULE, []).

init([]) ->
	Dict = dict:store(mode, master, dict:new()),
	register(rootSr, self()),
	%%register(rootLB,self()),
    {ok, {{one_for_one, 3, 60},
         [{serviceRegisterSupervisor,
           {serviceRegisterSupervisor, start_link, [Dict]},
           permanent, 1000, supervisor, [serviceRegisterSupervisor]}	
         ]}}.
