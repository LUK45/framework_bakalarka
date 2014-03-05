-module(serviceRegister).

-compile(export_all).


%%%% service register 
%% adresy laod balancerov ... 
%%% kazdy ma svoj status -> master / normal
%%% master -> pridava odobera lbss / spravuje repliky




start(Mode, Dict) ->
	io:format("serviceRegister ~p: nastartovany moje pid je ~p a moj mod je ~p~n", [self(),self(), Mode]),
	if 
		Mode =:= master ->
			MyMonitor = serviceRegisterMonitor:start(sr);
		true ->
			MyMonitor = serviceRegisterMonitor:start(self())
			
	end,		
	io:format("serviceRegister: moj monitor: ~p~n",[MyMonitor]),
	%Dict = null,   %%%%% pri nastartovani este nei je ziadny dict s lbss
	%LbSrPid = null, %% !!!!!!!!!!!!!!!!! to mozem odtranit ak bude vzdy registrovany ako lbsr
	if
		%%% po rerstarte monitorom 
		Dict =:= null ->
			io:format("serviceRegister: mam dict null~n"),
			lbsr ! {self(), giveDict},
			receive
				{Pid, dict, Dict2} ->
					ok
			after 5000 ->
				io:format("serviceRegister: lbsr neodpoveda!~n"),
				Dict2 =  null		
			end;
		true ->
			io:format("serviceRegister: nemam dict null~n"),
			Dict2 = Dict
	end,
	
	if %% predstavi sa lbsr ze je master
		Mode =:= master ->
			io:format("serviceRegister~p: som master, predstavim sa lbsr~n",[self()]),
			lbsr ! {self(), masterSR};
		true ->	
			lbsr ! {self(), newMirror},
			io:format("serviceRegister~p: som mirror, predstavim sa lbsr~n",[self()])
	end,	
	
	io:format("serviceRegister: moj dict ~p~n",[Dict2]),
	loop(Mode, Dict2).
	



loop(Mode, Dict) ->
	receive 
		%%% lbsr sa predstavuje, master mu odpovie svojim pid
		{Pid, lbsr} ->
			io:format("serviceRegister ~p: som ~p dostal som spravu lbsr od ~p~n", [self(),self(),Pid]),
			if
				Mode =:= master ->
					Pid ! {self(), masterSR},
					io:format("serviceRegister ~p: ~p som master odpovedal som ~n", [self(),self()]);
				true ->
					io:format("serviceRegister ~p: ~p ni som master neodpovedam~n", [self(),self()])	

			end,
			%LbSrPid2 = Pid,
			loop(Mode, Dict);
		%% najdi lbss pre danu sluzbu (ServiceID) a posli jeho adresu workerovi ktory si ju ziada, kontorluje sa ci slovnik existuje   ???? upravit Pid na LbsrPid?
		{Pid , findLbSs, ServiceId, WorkerPid} ->
			io:format("serviceRegister~p: dostal som poziadavku pre najdenie lbss pre serviceID ~p pre workera ~p od lbsr ~p ~n", [self(),ServiceId, WorkerPid, Pid]),
			if
				Dict =:= null ->
					io:format("serviceRegister: dictionary neexiustuje, nemozem najst LbSs ~n"),
					loop(Mode, Dict);
				true ->
					case
						dict:is_key(ServiceId,Dict) of
						true ->
							io:format("serviceRegister: platny kluc service id~n"),
							LbSsPid = findLbSs(ServiceId, Dict),
							io:format("serviceRegister: lbss pre serviceID ~p je ~p~n", [ServiceId, LbSsPid]),
							WorkerPid ! {self(), findLbSs, ServiceId, LbSsPid},
							loop(Mode, Dict);
						false ->
							io:format("serviceRegister: neplatny kluc service id~n"),
							WorkerPid ! {self(), findLbSs, noSuchServiceId, null},
							loop(Mode, Dict)

					end
								
			end;			

		%% vytore novy dict s lbss -> moze iba master -> kontroluje sa mode a to ci uz dict neexistuje	
		{createDict} ->
			io:format("serviceRegister: request z consoly na vytvorenie noveho dictionary~n"),
			if
				Mode =:= master ->
					io:format("serviceRegister: som master a mozem vykonat tento request ~n"),
					if
						Dict =:= null ->
							Dict1 = createDictOfLbSs(),
							io:format("serviceRegister: novy dict je ~p~n", [Dict1]),
							loop(Mode, Dict1);
						true ->
								
							io:format("serviceRegister: dictionary uz existuje, nevytvaram novy~n"),
							loop(Mode, Dict)	
					end;
				true ->
					io:format("serviceRegister: nie som master tak tento request nemozem vykonat~n"),
					loop(Mode, Dict)			
			end;

		%% ukaze vsetky dostupne Id sluzieb -> kontorluje sa ci uz je nejaky slovnik vytvoreny	
		{showServiceIds} ->
			io:format("serviceRegister: request z consoly na vypisanie vsetkych klucov -> seriveIDs~n"),
			if
					Dict =:= null ->
						io:format("serviceRegister: dictionary este nebol vytvoreny~n"),
						loop(Mode, Dict);
					true ->
						showAllKeys(Dict),
						io:format("serviceRegister: requerst vykonany ~n"),
						loop(Mode, Dict)				
			end;


		%% ukaze vsetky pary sluzba - lbss -> kontorluje sa ci uz je nejaky slovnik vytvoreny	
		{showAllPairs} ->
			io:format("serviceRegister: request z consoly na vypisanie vsetkych parov sluzba - load balancer~n"),
			if
					Dict =:= null ->
						io:format("serviceRegister: dictionary este nebol vytvoreny~n"),
						loop(Mode, Dict);
					true ->
						showAllPairs(Dict),
						io:format("serviceRegister: requerst vykonany ~n"),
						loop(Mode, Dict)				
			end;

		%%% prida service id do dict , treba vytvorit lbss , kontorluje sa ci je master a ci uz existuje dict	
		{addService, ServiceId} ->
			io:format("serviceRegister: request z consoly na pridanie novej sluzby~n"),
			if
				Mode =:= master ->
					io:format("serviceRegister: som master a mozem vykonat tento request ~n"),
					if
						Dict =:= null ->
							io:format("serviceRegister: dictionary este nebol vytvoreny~n"),
							loop(Mode, Dict);
						true ->
							Dict1 = addServiceId(Dict, ServiceId),
							io:format("serviceRegister: novy dict je ~p ~n", [Dict1]),
							%%% informuje lbsr o zmene dict aby sa mohjli aktualizovat mirrors
							lbsr ! {self(), newDict, Dict1},
							loop(Mode, Dict1)
					end;
				true ->
					io:format("serviceRegister: nie som master tak tento request nemozem vykonat~n"),
					loop(Mode, Dict)			
			end;
		%%% informuj lbsr o dictionary, pri tom ako sa vytbvara mirror lbsr sa dozaduje o dict	
		{_Pid, giveDict} ->
			io:format("serviceRegister~p: dostal som ziadost give dictionary od lbsr~n",[self()]),
			lbsr ! {self(), dict, Dict},
			io:format("serviceRegister: poslal som dictionary~n"),
			loop(Mode,Dict);
		%%%% aktualizacia mirror, dostal som od lbsr aktualny dict	
		{_Pid, dict, Dict2} ->
			io:format("serviceRegister: ~p dostal som dictionary~n",[self()]),
			loop(Mode, Dict2);	
		
			%% kill signal
		{die, Pid, Reason} ->
			io:format("serviceRegister: prijal som die signal od ~p~n", [Pid]),
			exit(Reason);


		{normal} -> io:format("serviceRegister: normal end~n");


		Any ->
			io:format("serviceRegister~p: unknown request ~p~n",[self(),Any]),
			loop(Mode, Dict)			
					
	end.
	


%%%%  tuna bude praca s dictionary -> podla id sluzby sa najde prislusny lbss
findLbSs(ServiceId, Dict) ->
	LbSsPid = dict:fetch(ServiceId, Dict),
	LbSsPid.	

%%%% vytvori novy dict s lbss pre ss  -> iba master
createDictOfLbSs() ->
	Dict = dict:new(),
	Dict.

%%% list vsetkych klucov -> serviceID -> moze kazdy sr
showAllKeys(Dict) ->
	io:format("SR-showAllKeys~n"),
	io:format("~p~n",[dict:fetch_keys(Dict)]),
	io:format("SR-showAllKeys-finished~n").

%%% pridaj servie id do slovnika -> pri pridani novej sluzby -> treba zaroven vytvorit novy lbss a jeho adresu pridat danemu klucu
addServiceId(Dict, ServiceId) ->
	NewPid = spawn(fun() -> loadBalancerSS:start(ServiceId)end),
	Dict1 = dict:store(ServiceId, NewPid, Dict),
	Dict1.	

%% ukaz vsetky dvojice ServiceId - LbSsPid --list
showAllPairs(Dict) ->
	io:format("SR-shwoAllPairs~n"),
	io:format("~p~n",[dict:to_list(Dict)]),
	io:format("SR-shwoAllPairs-finished~n").










