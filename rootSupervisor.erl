-module(rootSupervisor).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link(?MODULE,[]).

init([]) ->
	register(root, self()),
    {ok, {{one_for_one, 3, 60},
         [{rootSr,
           {rootSrSupervisor, start_link, [{master,masterRoot}]},
           permanent, 1000, supervisor, [rootSrSupervisor]},
          {rootLb,
            {rootLbSupervisor, start_link, []},
            permanent, 1000, supervisor, [rootLbSupervisor]},
          {rootWs,
            {rootWsSupervisor, start_link, []},
            permanent, 1000, supervisor, [rootWsSupervisor]}   	
         ]}}.
