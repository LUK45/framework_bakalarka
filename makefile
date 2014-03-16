.SUFFIXES: .erl .beam 

.erl.beam:
	erlc -W $<

ERL = erl -boot start_clean 


MODS = gate worker worker_spawner wtimer loadBalancerSR cache_handler \
		loadBalancerRoundRobin serviceServer loadBalancerSS serviceRegister \
		rootSupervisor rootLbSupervisor rootSrSupervisor \
		initModule lbsrSupervisor serviceRegisterSupervisor rootWsSupervisor \
		workerSpawnerSupervisor



all: compile

compile: ${MODS:%=%.beam} 

clean:	
	rm -rf *.beam erl_crash.dump
	
