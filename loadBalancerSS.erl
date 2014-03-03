-module(loadBalancerSS).

-compile(export_all).


%%% laod balancer pre service serve -> serrvice register spravuje zoznam tychto laod balancerov
%%% tieto load balancery rozkladaju zataz medzi service servre danej sluzby

%%% start lbss, serviceId konktretnej sliuzby, ???? otazne je co s listom serverou ktore spracuva
start(ServiceId) ->
	io:format("loadBalancerSS: nastartovany, moje pid je ~p a spravujem Service ~p~n",[self(), ServiceId]),
	loop(ServiceId).

loop(_ServiceId) -> void.	