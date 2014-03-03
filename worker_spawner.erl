-module(worker_spawner).

%-compile(erxport_all).
-export([spawn_worker/4, start/4]).


%% start() -> gate ho takto startuje
start(Session, Name, Lbsr_pid, Ch_pid) -> 
	io:format("workerspawner: nastartovany , moje pid je ~p~n", [self()]),
	spawn_worker(Session, Name, Lbsr_pid, Ch_pid).



%% startuje wokrera -> musi poznat adresu cache handlera a load balancera pre serrvice registre, dalej spusti loop v ktorej caka na vysledkok od workera
spawn_worker(Session, Name, Lbsr_pid, Ch_pid) -> 
	MojePid = self(),
	register(Name,WorkerPid = spawn(fun() -> worker:start(Lbsr_pid, Ch_pid, MojePid) end)),
	loop(Session,Name, WorkerPid).



%% worker spawner caka na vysledok od workera 
loop(Session,Name, WorkerPid) ->
	%Name ! {self(),koniec},
	io:format("worker spawner: moje pid je ~p workerove pid je: ~p a meno: ~p ~n", [self(),WorkerPid, Name]),
	receive 
		{WorkerPid, Msg} -> 
			io:format("worker spawner: ~p~n",[Msg]),
			loop(Session,Name, WorkerPid);
		Any ->	
			io:format("worker spawner: any ~p~n",[Any]),
			loop(Session,Name, WorkerPid)
	%after 5000 ->
			
	%	io:format("workerspawner: spawner presiel cas~n")
		
	end.			