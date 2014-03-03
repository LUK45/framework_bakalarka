-module(makefile).
-export([compile/0]).

compile() ->
	compile_core(),
%	compile_services(),
	ok.
	
compile_core() ->
	c:c(gate),
	io:format("==================================~nmakefile: gate.erl compiled~n~n"),
	c:c(worker),
	io:format("makefile: worker.erl compiled~n~n"),
	c:c(worker_spawner),
	io:format("makefile: worker_spawner.erl compiled~n~n"),
	c:c(wtimer),
	io:format("makefile: wtimer.erl compiled~n~n"),
	c:c(loadBalancerSR),
	io:format("makefile: loadBalancerSR.erl compiled~n~n"),
	c:c(cache_handler),
	io:format("makefile: cache_handler.erl compiled~n~n"),
	c:c(loadBalancerRoundRobin),
	io:format("makefile: loadBalancerRoundRobin.erl compiled~n~n"),
	c:c(serviceServer),
	io:format("makefile: serviceServer.erl compiled~n~n"),
	c:c(loadBalancerSS),
	io:format("makefile: loadBalancerSS.erl compiled~n~n"),
	c:c(serviceRegister),
	io:format("makefile: serviceRegister.erl compiled~n~n"),
	c:c(initModule),
	io:format("makefile: initModule.erl compiled~n~n"),
	c:c(errorHandler),
	io:format("makefile: errorHandler.erl compiled~n~n"),
		ok.
	
