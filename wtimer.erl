-module(wtimer).

-export([start/2]).

%%% timer modul, je prideleny kazdemu workerovi
%%% meria cas, ktory je v ramci SLA povoleny pre dany request, pokial sa prkroci a request nie je obsluzeny, vykona funkciu ktora je parametrom pre nastartovanie casovaca!!

start(Worker,Time) -> 
	io:format("timer: nastartovany oje pid je ~p a mojho workera je ~p~n", [self(),Worker]),
	receive 
		Any -> io:format("timer: ~p ~n", [Any])
	after Time ->
		io:format("timer: idem posielat finish signal na pid: ~p ~n", [Worker]),
		Worker ! {self(),finish}
	end.	



