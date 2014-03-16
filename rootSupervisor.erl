-module(rootSupervisor).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link(?MODULE,[]).

init([]) ->
	register(root, self()),
    {ok, {{one_for_one, 3, 60},
         [{rootSrSupervisor,
           {rootSrSupervisor, start_link, []},
           permanent, 1000, supervisor, [rootSrSupervisor]},
          {rootLbSupervisor,
            {rootLbSupervisor, start_link, []},
            permanent, 1000, supervisor, [rootLbSupervisor]},
          {rootWsSupervisor,
            {rootWsSupervisor, start_link, []},
            permanent, 1000, supervisor, [rootWsSupervisor]}   	
         ]}}.
