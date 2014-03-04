-module(errorHandler).

-compile(export_all).




%%%% error handler 

start(Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList) ->

	io:format("errorHandler: som nastartovany, moje pid je ~p~n", [self()]),
	process_flag(trap_exit, true),
	%link(SrMst_pid),
	%link(Ch_pid),
	%link(Lbsr_pid),
	%link(Ws_pid),
	loop(state,Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList).	


loop(_State, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList) ->
	
	receive 
		%% srmst je dead
		%% treba informovat lbsr, vyradit zo SRlist, zistit ci je nejaky mirror, vybrat mirrror/spawnut novy sr, dict
	%	{'EXIT', SrMst_pid, Reason} ->
	%		io:format("errorHandler: prijal som exit signal od MstSr pid: ~p dovod: ~p ~n", [SrMst_pid, Reason]),
	%		SRList2 = lists:delete(SrMst_pid, SRList),
	%		Lbsr ! {self(), iAmEh, srMstDown},
	%			if
	%						SRList2 =:= [] ->  %% srlist je prazdny, spawnem noveho srmst
	%							io:format("errorHandler: SRList je prazdny, spawnem noveho mastra~n"),
	%							register(SrMst, SrMst_pid2 = spawn(fun() -> serviceRegister:start(master,null) end)),
	%							io:format("errorHandler: restartoval som sr, jeho pid je ~p~n",[SrMst_pid2]),
	%							link(SrMst_pid2),  %% linknem novy sr
	%							SRList3 = SRList2 ++ [SrMst_pid2], %% pridam ho do listu pre seba
	%							Lbsr ! {self(), iAmEh, newSrList, SRList3, newMstPid, SrMst_pid2},
	%							io:format("errorHandler: informoval som lbsr, novy srlist ~p, novy mst ~p ~n", [SRList3,SrMst_pid2] ),
	%							loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid2,SRList3);
	%						true ->
	%							io:format("errorHandler: SRList nie je prazdny, spawnem noveho mastra, odovzdam mu dict~n"),
	%							Lbsr ! {self(), iAmEh, giveDict},
	%							receive
	%								{Lbsr_pid, dict, Dict} ->
	%									register(SrMst, SrMst_pid3 = spawn(fun() -> serviceRegister:start(master,Dict) end)),
	%									io:format("errorHandler: restartoval som sr, jeho pid je ~p~n",[SrMst_pid3]),
	%									link(SrMst_pid3),
	%									SRList3 = SRList2 ++ [SrMst_pid3],
	%									Lbsr ! {self(), iAmEh, newSrList, SRList3, newMstPid, SrMst_pid3},
	%									io:format("errorHandler: informoval som lbsr, novy srlist ~p, novy mst ~p ~n", [SRList3,SrMst_pid3] ),
	%									loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid3,SRList3)
	%							end				
	%			end;
	

		%% ch je dead
		{'EXIT', Ch_pid, Reason} ->
			io:format("errorHandler: prijal som exit signal od ch pid: ~p dovod: ~p ~n", [Ch_pid, Reason]),

			%zatial ho len spustim znovu
			register(Ch, Ch_pid2 = spawn(fun() -> cache_handler:start() end)),
			io:format("errorHandler: restartoval som ch, jeho pid je ~p~n",[Ch_pid2]),
			link(Ch_pid2),
			loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid2, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList);	

		%% lbsr je dead
		{'EXIT', Lbsr_pid, Reason} ->
			io:format("errorHandler: prijal som exit signal od lbsr pid: ~p dovod: ~p ~n", [Lbsr_pid, Reason]),


			
			%zatial ho len spustim znovu
			register(Lbsr, Lbsr_pid2 = spawn_link(fun() -> loadBalancerSR:start(SRList) end)),
			io:format("errorHandler: restartoval som lbsr, jeho pid je ~p~n",[Lbsr_pid2]),
			loop(state1, Lbsr,Lbsr_pid2, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList);

		%% moze ist o hocico ine
		%% zatial zistujem ci to neni mirror sr
		{'EXIT', Pid, Reason} ->
		io:format("errorHandler: prijal som exit signal od ~p s dovodom ~p~n",[Pid,Reason]),
			case Reason of	%% zistujem dovod 
				normal -> 		% normal -> proces skoncil uspesne , napr lbsr zrusil mirror
					case isSrMirror(Pid,SRList) of	%% ci ide o mirror
						true ->
							SRList2 = lists:delete(Pid, SRList),
							io:format("errorHandler: reason -normal, bol to SrMirror, novy SRList je ~p =>ok~n",[SRList2]),
							loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList2);
						false ->
							io:format("errorHandler: reason - normal, nie je to SrMirror => ok.~n"),
							loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList)
					end;				

				X  -> %% ine dovody
					case isSrMirror(Pid,SRList) of
						true ->
							SRList2 = lists:delete(Pid, SRList),
							Lbsr ! {self(), iAmEh, newSrList, SRList2},
							Lbsr ! {self(), iAmEh, giveDict},
								receive
									{Lbsr_pid, dict, Dict} ->
										NewSrMirror = spawn_link(fun() -> serviceRegister:start(normal,Dict) end),
										io:format("errorHandler: restartoval som srmirror, jeho pid je ~p~n",[NewSrMirror]),
										SRList3 = SRList2 ++ [NewSrMirror],
										Lbsr ! {self(), iAmEh, newSrList, SRList3, newMirror, NewSrMirror},
										io:format("errorHandler: reason - ~p,  je to SrMirror  ~p novysrlist ~p=> ok.~n",[X, NewSrMirror, SRList3]),
										loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList3)
								end;
						false ->		%% nebol to service register, je to nieco ine
							io:format("errorHandler: reason - ~p, nie je srmirror, zatial neriesim => ok~n", [X]), %!!!!!!!!!!!!!!!!! 
							loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList)
					end

					
			end,
			
			loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList);					


		%% skusobny contact lbsr 
		{contactLBSR} ->
			io:format("serviceRegister: kontaktujem lbsr~n"),
			Lbsr_pid ! {self(),iAmEh},
			loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList);	


		%% lbsr vytrvoril novy sr mirror, nalinmkkujem si ho
		{Lbsr_pid, iAmLbSr, linkThis, NewSr} ->
			io:format("errorHandler: lbsr vytvoril mirror sr : ~p, nalinkujem si ho~n",[NewSr]),
			link(NewSr),
			SRList2 = SRList ++ [NewSr],
			loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList2);	
		
		%% vypisat sr list 
		{showSRList} ->
			io:format("errorHandler: moj SRList je ~p~n",[SRList]),
			loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList);			

	

		Any ->
			io:format("errorHandler: prijal som  ~p  ~n", [Any]),
			loop(state1, Lbsr,Lbsr_pid, Ch,Ch_pid, Ws_name,Ws_pid, SrMst,SrMst_pid,SRList)		
	%after 2000 ->
	%	io:format("initModule: ttttttttttttttttttttttttttttt~n")		

	end.			

%% funckia pre zistenie ci je dane pid niektoreho zrkadla service registra
isSrMirror(Pid,SRList) ->
	lists:member(Pid,SRList).

				

