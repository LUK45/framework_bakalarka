-module(workerSpawnerSupervisor).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link(?MODULE, []).

init([]) ->
	%register(rootWs, self()),
	WState = dict:store(myWorker, null,dict:new()),
	%%register(rootLB,self()),
    {ok, {{one_for_one, 3, 60},
         [{worker_spawner,
           {worker_spawner, start_link, [WState]},
           permanent, 1000, worker, [worker_spawner]}	
         ]}}.

