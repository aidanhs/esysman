%% Copyright (c) 2012, Wes James <comptekki@gmail.com>
%% All rights reserve.
%% 
%% Redistribution and use in source and binary forms, with or without
%% modification, are permitted provided that the following conditions are met:
%% 
%%     * Redistributions of source code must retain the above copyright
%%       notice, this list of conditions and the following disclaimer.
%%     * Redistributions in binary form must reproduce the above copyright
%%       notice, this list of conditions and the following disclaimer in the
%%       documentation and/or other materials provided with the distribution.
%%     * Neither the name of "ESysMan" nor the names of its contributors may be
%%       used to endorse or promote products derived from this software without
%%       specific prior written permission.
%% 
%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%% POSSIBILITY OF SUCH DAMAGE.
%% 
%%

-module(websocket_handler).
-export([
		 init/3,
		 handle/2,
		 terminate/3
		]).
-export([
		 websocket_init/3,
		 websocket_handle/3,
		 websocket_info/3,
		 websocket_terminate/3
		]).

%im().
%ii(websocket_handler).
%iaa([init]).

-include("esysman.hrl").
-include("db.hrl").

init(_Transport, Req, []) ->
	case cowboy_req:header(<<"upgrade">>, Req) of
		{undefined, Req2} ->
			{ok, Req2, undefined};
		{<<"websocket">>, _Req2} ->
			{upgrade, protocol, cowboy_websocket};
		{<<"WebSocket">>, _Req2} ->
			{upgrade, protocol, cowboy_websocket}
	end.

terminate(_Reason, _Req, _State) ->
	ok.

websocket_init(_Any, Req, []) ->
	case lists:member(hanwebs, registered()) of
		true -> ok;
		false ->
			register(hanwebs, self())
	end,
	Req2 = cowboy_req:compact(Req),
	{ok, Req2, undefined, hibernate}.

websocket_handle({text, <<"close">>}, Req, State) ->
			{shutdown, Req, State};
websocket_handle({text, <<"client-connected">>}, Req, State) ->
			{reply, {text, <<"client-connected">> }, Req, State, hibernate};
websocket_handle({text, Msg}, Req, State) ->
	Ldata=binary:split(Msg,<<":">>,[global]),
	io:format("~nLdata: ~p~n",[Ldata]),
	[Box,Com,Args]=Ldata,
	Rec_Node=binary_to_atom(<<Box/binary>>,latin1),
	case Com of
		<<"com">> ->
			{rec_com, Rec_Node} ! {Box,Com,Args},
			Data2= <<"com -> ",Args/binary,"  <- sent to: ",Box/binary>>,
			io:format("~n done com: ~p - args: ~p~n",[Box,Args]);
		<<"loggedon">> ->
			{rec_com, Rec_Node} ! {Box,Com,<<"">>},
			Data2= <<"loggedon sent to: ",Box/binary>>,
			io:format("~n done loggedon ~p - data2: ~p ~n",[Box, Data2]);
		<<"copy">> ->
			case file:read_file(<<?UPLOADS/binary,Args/binary>>) of
				{ok, DataBin} ->
					{rec_com, Rec_Node} ! {Box,Com,{Args,DataBin}},
					Data2= <<"copy sent to: ",Box/binary>>,
					io:format("~n done copy - ~p ~n",[Box]);
				{error, Reason} ->
					Data2= <<Box/binary,":copy error-",(atom_to_binary(Reason,latin1))/binary>>,
					io:format("~n done copy - ~p - error: ~p~n",[Box, Reason])
			end;
		<<"dffreeze">> ->
			{rec_com, Rec_Node} ! {Box,Com,<<"">>},
			Data2= <<Box/binary,":dffreeze">>,
			io:format("~n done dffreeze ~p - data2: ~p ~n",[Box, Data2]);
		<<"dfthaw">> ->
			{rec_com, Rec_Node} ! {Box,Com,<<"">>},
			Data2= <<Box/binary,":dfthaw">>,
			io:format("~n done dfthaw ~p - data2: ~p ~n",[Box, Data2]);
		<<"dfstatus">> ->
			{rec_com, Rec_Node} ! {Box,Com,<<"">>},
			Data2= <<"dfstatus sent to: ",Box/binary>>,
			io:format("~n done dfstatus ~p - data2: ~p ~n",[Box, Data2]);
		<<"net_restart">> ->
			{rec_com, Rec_Node} ! {Box,Com,<<"">>},
			Data2= <<"net_restart sent to: ",Box/binary>>,
			io:format("~n done net_restart ~p - data2: ~p ~n",[Box, Data2]);
		<<"net_stop">> ->
			{rec_com, Rec_Node} ! {Box,Com,<<"">>},
			Data2= <<"net_stop sent to: ",Box/binary>>,
			io:format("~n done net_stop ~p - data2: ~p ~n",[Box, Data2]);
		<<"reboot">> ->
			{rec_com, Rec_Node} ! {Box,Com,<<"">>},
			Data2= <<"reboot sent to: ",Box/binary>>,
			io:format("~n done reboot ~p - data2: ~p ~n",[Box, Data2]);
		<<"shutdown">> ->
			{rec_com, Rec_Node} ! {Box,Com,<<"">>},
			Data2= <<"shutdown sent to: ",Box/binary>>,
			io:format("~n done shutdown ~p - data2: ~p ~n",[Box, Data2]);
		<<"wol">> ->
			MacAddr=binary_to_list(Args),
			MacAddrBin= <<<<(list_to_integer(X, 16))>> || X <- string:tokens(MacAddr,"-")>>,
			MagicPacket= << (dup(<<16#FF>>, 6))/binary, (dup(MacAddrBin, 16))/binary >>,
			{ok,S} = gen_udp:open(0, [{broadcast, true}]),
			gen_udp:send(S, ?BROADCAST_ADDR, 9, MagicPacket),
			gen_udp:close(S),
			Data2= <<"done wol: ",Box/binary,"....!">>,
			io:format("~n done wol - ~p ~n",[Box]);
		  <<"ping">> ->
			{rec_com, Rec_Node} ! {Box,Com,<<"">>},
			Data2= <<"ping sent to: ",Box/binary>>,
			io:format("~n done ping ~p - data2: ~p ~n",[Box, Data2]);
		_ ->
			Data2= <<"unsupported command">>
	end,
	{reply, {text, Data2}, Req, State, hibernate};
websocket_handle(_Any, Req, State) ->
	{ok, Req, State}.

dup(B,Acc) when Acc > 1 ->	
    B2=dup(B, Acc-1),
	<< B/binary,  B2/binary >>;
dup(B,1) ->
    B.

websocket_info(PreMsg, Req, State) ->
	Msg=
		case PreMsg of
			{Msg2,_PID}-> Msg2;
			_ -> PreMsg
		end,
	Msg3 = 
		case is_binary(Msg) of
			true -> Msg;
			false -> list_to_binary(Msg)
		end,
	chk_insert(binary:split(Msg3, <<"/">>, [global])),
	{reply, {text, Msg3}, Req, State, hibernate}.

chk_insert([_]) -> ok;
chk_insert([_, <<"pong">>]) -> ok;
chk_insert([_, _, <<>>]) ->	ok;
chk_insert([B1, _, B2]) ->
	{{Year, Month, Day}, {Hour, Min, _}} = calendar:local_time(),
	TimeStamp = list_to_binary(io_lib:format("~p-~2..0B-~2..0B ~2..0B:~2..0B", [Year, Month, Day, Hour, Min])),
	do_insert(TimeStamp, B1, B2);
chk_insert(_Data) when length(_Data) >= 2 -> ok.

websocket_terminate(_Reason, _Req, _State) ->
	ok.

fire_wall(Req) ->	
	{PeerAddress, _Req}=cowboy_req:peer_addr(Req),
	{ok, [_,{FireWallOnOff,IPAddresses},_,_]}=file:consult(?CONF),
	case FireWallOnOff of
		on ->
			case lists:member(PeerAddress,IPAddresses) of
				true ->
					allow;
				false ->
					deny
			end;
		off -> allow
	end.

login_is() ->
	{ok, [_,_,{UPOnOff,UnamePasswds},_]}=file:consult(?CONF),
	case UPOnOff of
		on -> UnamePasswds;
		off -> off
	end.
	
%%

checkCreds(UnamePasswds, Req, _State) ->
	[{Uname,_}] = UnamePasswds,
	{C, Req1} = cowboy_req:cookie(Uname, Req),
    case (C == undefined) or (C == <<>>) of
		true ->
			checkPost(UnamePasswds, Req1);
		false  ->
			CookieVal = get_cookie_val(), 
			Req2 = cowboy_req:set_resp_cookie(Uname, CookieVal, [{max_age, ?MAXAGE}, {path, "/"}, {secure, true}, {http_only, true}], Req1),
			{pass, Req2}
	end.

%

checkCreds([{Uname,Passwd}|UnamePasswds], Uarg, Parg, Req) ->
    case Uname of
		Uarg ->
			case Passwd of
				Parg ->
					CookieVal = get_cookie_val(), 
					Req0 = cowboy_req:set_resp_cookie(Uname, CookieVal, [{max_age, ?MAXAGE}, {path, "/"}, {secure, true}, {http_only, true}], Req),
					{pass, Req0};
				_ ->
					checkCreds(UnamePasswds,Uarg,Parg,Req)
			end;
		_ ->
			checkCreds(UnamePasswds, Uarg, Parg, Req)
	end;
checkCreds([], _Uarg, _Parg, Req) ->
	{fail, Req}.

%

checkPost(UnamePasswds,Req) ->
	case cowboy_req:method(Req) of
		{<<"POST">>, Req0} ->
			{ok, FormData, Req1} = cowboy_req:body_qs(Req0),
			case FormData of
				[{_UnameVar,UnameVal},{_PasswdVar,PasswdVal},_Login] ->
					checkCreds(UnamePasswds,UnameVal,PasswdVal,Req1);
				_ ->
					{fail,Req}
			end;
		_ ->
			{fail,Req}
	end.

%

get_cookie_val() ->
	list_to_binary(
	  integer_to_list(
		calendar:datetime_to_gregorian_seconds({date(), time()})
	   )).

%



handle(Req, State) ->
case fire_wall(Req) of
		allow ->
			Creds=login_is(),
			case is_list(Creds) of
				true ->
					{Cred, Req0} = checkCreds(Creds, Req, State),
					case Cred of
						fail ->
							static_gen:app_login(Req0, State);
						pass ->
							static_gen:app_front_end(Req0, State)
					end;
				false -> 
					case Creds of
						off ->
							static_gen:app_front_end(Req, State);
						_  ->
							static_gen:app_login(Req, State)
					end
			end;
		deny ->
			static_gen:fwDenyMessage(Req, State)
	end.

%

do_insert(TimeStamp, Box, User) ->
	S = <<"insert into esysman (atimestamp, abox, auser) values ('", TimeStamp/binary, "', '", Box/binary, "', '", User/binary, "')">>,
	case pgsql:connect(?DBHOST, ?USERNAME, ?PASSWORD, [{database, ?DB}, {port, ?PORT}]) of
		{error,_} ->
			{S, error};
		{ok, Db} -> 
			case pgsql:squery(Db, S) of
				{error,Error} ->
					io:format("insert error: ~p~n", [Error]),
					{S, error};
				{_,Res} ->
					pgsql:close(Db),
					{S, Res}
			end
	end.
