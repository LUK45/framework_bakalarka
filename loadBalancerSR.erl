-module(loadBalancerSR).

-export([start/1]).


%%% moudl LB SR -> load balancer pre service registre

start(SRList) ->
io:format("loadbalancerSR: nastartovany , moje pid je ~p~n", [self()]),
	%SRList = [s1,s2,s3,s4],
	%%% predstavi sa vsetkym sr, a caka odpoved od mastra aby vedel jeho pid
	if
		SRList =:= [] ->
			io:format("loadbalancerSR: mam prazdny list sr~n"),
			MasterSrPid = null;
		true ->
			io:format("loadBalancerSR: srlist je ~p~n",[SRList]),
			lists:foreach(fun(Pid) ->  Pid ! {self(), lbsr} end, SRList),
			receive 
				{MasterSrPid , masterSR} -> 
					io:format("loadBalancerSR: masterSrPid je ~p~n", [MasterSrPid])
			end	
	end,
			
	loop(SRList, MasterSrPid).


%%%% pridat service register
%% obsluhuje sprava {addMirror}
%addServiceRegister() -> void.





%%%%%% loop s argumentom listom dostuypnych serivec registrov -> zatial provizorne
loop(SRList,MasterSrPid) ->
	%io:format("********************~n"),
	receive 
		%%% ziskaj adresu service registra -> toto sa vo fdinale nebude pouzivat 
		{Pid, findSR} ->
			{SrPid, SRList2, _St} = loadBalancerRoundRobin:selectServer(SRList,state),
			Pid ! {self(), findSR, SrPid},
			loop(SRList2,MasterSrPid);
		%%% ziskaj adresu load balancera pre servery konktretnej sluzby
		{WorkerPid, findLbSs, ServiceId} ->
			io:format("Lbsr: dostal som poziadavku pre zistenie adresy lbss pre sluzbu s id ~p -> kontaktujem sr~n", [ServiceId]),
			if
				SRList =:= [] ->
					io:format("loadBalancerSR: srlist je prazdny, nemozem obluszit poziadavu~n"),
					WorkerPid ! {self(), noSr},
					loop(SRList, MasterSrPid);
				true ->
					{SrPid, SRList2, _St} = loadBalancerRoundRobin:selectServer(SRList,state),
					SrPid ! {self(), findLbSs, ServiceId, WorkerPid},
					loop(SRList2,MasterSrPid)	
			end;
			
		%%% ocakava odpoved ???? zatial druha varianta -> vid progerssslod day2 -> zatial neocakava	

		

		%% vytvor novy mirror service registra	
		{addMirror,name,Name} ->
			io:format("Lbsr: vytvor mirror~n"),
			%% poziada mastra o dict 
			MasterSrPid ! {self(), giveDict},
			receive 
				{MasterSrPid, dict, Dict} ->
					io:format("Lbsr: dostal som dictionary od mastra~n")
			end,
			%% spawne novy proces so sr, mode normal -> nie master, dict zatial null, prida ho do listuSr, a predstavi sa mu
			register(Name,NewSr = spawn(fun() -> serviceRegister:start(normal,Dict) end)),
			SRList2 = SRList ++ [NewSr],
			%NewSr ! {self(), lbsr},
			io:format("Lbsr: novy mirror je ~p a novy sr list je ~p~n", [NewSr, SRList2]),
			
			
			%io:format("Lbsr: informujem Eh aby si nalinkoval noveho mirrora~n"),
			%eh ! {self(), iAmLbSr, linkThis, NewSr},
			loop(SRList2,MasterSrPid);

			%% kill signal
		{die, Pid, Reason} ->
			io:format("Lbsr: prijal som die signal od ~p~n", [Pid]),
			exit(Reason);	


		%%% skusobne skontaktovanie eh  ----ok
		{contactEH} ->
			io:format("loadBalancerSR: kontaktujem eh~n"),
			eh ! {self(),iAmLbSr},
			loop(SRList, MasterSrPid);	



		%%% zmienil sa dict -> aktualizovat mirrors	
		{MasterSrPid, newDict, Dict} ->	
			lists:foreach(fun(Pid) -> updateDict(Pid, MasterSrPid, Dict) end, SRList),
			loop(SRList, MasterSrPid);

		%% error handler si vyziadal sr list !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
		{Pid, iAmEh, giveSrList} ->
			io:format("loadBalancerSR: eh si vyziadal sr list ~n"),
			Pid ! {self(), srList, SRList},
			io:format("loadbalancerSR: poslal som sr list ku eh na pid: ~p~n", [Pid]),
			loop(SRList, MasterSrPid);	

			%% sr monitor ma informuje ze srmst padol, treba ho vyradit zo srlist, poskytnut info pre eh aby mohol zvolit noveho srmst
		{_Pid,  srMstDown} ->
			io:format("loadBalancerSR: sr monitor ma informoval o pade srmst~n"),
			SRList2 = lists:delete(MasterSrPid, SRList),
			io:format("loadBalancerSR: socasny srlist bez mst je ~p~n",[SRList2]),

			MasterSrPid2 = null,
			loop(SRList2, MasterSrPid2);

		%% novy master sr sa predstavil
		{Pid , masterSR} -> 
			io:format("loadBalancerSR: masterSrPid je ~p~n", [Pid]),
			MasterSrPid2 = Pid,
			SRList2 = SRList ++ [MasterSrPid2],
			io:format("loadBalancerSR: new SRList ~p~n",[SRList2]),
			loop(SRList2,MasterSrPid2);		

		%% niekto si vypyta Dict 																	
		{Pid, giveDict} ->
			io:format("loadBalancerSR: eh si vypytal dict~n"),
			SrPid = lists:last(SRList),
			SrPid ! {self(), giveDict},
			receive 
				{SrPid, dict, Dict} ->
					io:format("Lbsr: dostal som dictionary od ~p ~p~n",[SrPid,Dict]),
					Pid ! {self(), dict, Dict}
			end,
			loop(SRList, MasterSrPid);	


			


		%% eh ma informuje o novom srliste a mst !!!!!!!!!!!!!!!!!!!!1
		{_Pid, iAmEh, newSrList, NewSrList, newMstPid, SrMst_pid2} ->
			SrMst_pid2 ! {self(), lbsr},
			io:format("loadbalancerSR: eh ma informoval new srlist ~p, new mst ~p~n",[NewSrList, SrMst_pid2]),
			loop(NewSrList,SrMst_pid2);	

		%% eh ma informuje o novom srliste !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
		{_Pid, iAmEh, newSrList, NewSrList} ->
			io:format("loadbalancerSR: eh ma informoval new srlist ~p, ~n",[NewSrList]),
			loop(NewSrList,MasterSrPid);	

			%% eh ma informuje o novom srliste a mirr !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
		{_Pid, iAmEh, newSrList, NewSrList, newMirror, NewSr} ->
			NewSr ! {self(), lbsr},
			io:format("loadbalancerSR: eh ma informoval new srlist ~p, new mst ~p~n",[NewSrList, MasterSrPid]),
			loop(NewSrList,MasterSrPid);		

		Any ->
			io:format("loadBalancerSR: prijal som ~p ~n", [Any]),
			loop(SRList, MasterSrPid)	

	end.		


%% aktualizuje diciotnary v replikach serivce registra
updateDict(Pid, MasterSrPid, Dict) ->
	if	
		Pid =/= MasterSrPid ->
				io:format("Lbsr: updatujem mirror ~p~n",[Pid]),
				Pid ! {self(), dict, Dict};
			true ->
				io:format("Lbsr: toto je master ~p neupdatujem mu dict~n", [Pid])	
	end.	
