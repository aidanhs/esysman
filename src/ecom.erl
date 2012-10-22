%% Copyright (c) 2012, Wes James <comptekki@gmail.com>
%% All rights reserved.
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

-module(ecom).

-export([start/0, rec_com/0]).

-include("ecom.hrl").

start() ->
    register(rec_com, spawn(ecom, rec_com, [])).

rec_com() ->
    receive
        finished ->
            io:format("finished~n", []);
        {Box, Com, Args} ->
            process_msg(Box, Com, Args),
            rec_com()
		after 60000 ->
				{hanwebs, ?NODE_AT_HOST} ! {comp_name()++?DOMAIN++"/pong",self()},
				{hanwebs, ?NODE_AT_HOST} ! {comp_name()++?DOMAIN++"/loggedon/"++logged_on(),self()},
				rec_com()
    end.

%process_msg(Box, Com, Args, Msg_PID) ->
process_msg(Box, Com, Args) ->
%	{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,": -> ", Com/binary, " - ", Args/binary>>,
    case Com of
		<<"com">> ->
            {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":com <- ",Args/binary>>,
			case Args of
				<<"mkuploads">> ->
					os:cmd("mkdir "++?UPLOADS_DIR),
					case ?PLATFORM of
						_ ->
							os:cmd("chmod 700 "++?UPLOADS_DIR);
						"w" -> ok
					end,
					{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,(list_to_binary(":mkdir "++?UPLOADS_DIR))/binary>>;
				<<"anycmd">> ->
					case ?PLATFORM of
						"w" ->
							os:cmd(?UPLOADS_DIR++"any.cmd");
						_ ->
							os:cmd("sh "++?UPLOADS_DIR++"any.cmd")
					end,
					{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":anycmd">>;
				<<"listupfls">> ->
					{hanwebs, ?NODE_AT_HOST} ! <<Box/binary, (list_to_binary(":listupfls:<br>"++list_up_fls()))/binary>>;
				<<"ninitecmd">> ->
					case ?PLATFORM of
						"w" ->
							os:cmd(?UPLOADS_DIR++"ninite.cmd"),
							{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":ninitecmd">>;
						_ ->
							{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":error - no function on this platform...">>
					end;
				<<"ninite">> ->
					case ?PLATFORM of
						"w" ->
							Date=get_date(),
							os:cmd("c:/erl/uploads/NiniteOne.exe /updateonly /exclude Python  /disableshortcuts /silent "++?UPLOADS_DIR++Date++"_log.txt"),
							{hanwebs, ?NODE_AT_HOST} ! <<Box/binary, (list_to_binary(":ninite date -> "++Date))/binary>>;
						_ ->
							{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":error - no function on this platform...">>
					end;
				<<"ninitelog">> ->
					case ?PLATFORM of
						"w" ->
							{ok,Files}=file:list_dir(?UPLOADS_DIR),
							Log=get_files(Files,n),
							case size(Log) of
								0 -> {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":no ninite logs">>;
								_ -> {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":ninitemlog -> ",Log/binary>>
							end;
						_ ->
							{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":error - no function on this platform...">>
					end;
				<<"aptulog">> ->
					case ?PLATFORM of
						"x" ->
							{ok,Files}=file:list_dir(?UPLOADS_DIR),
							Log=get_files(Files,a),
							case size(Log) of
								0 -> {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":no apt update log ">>;
								_ -> {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":apt-update-log -> ",Log/binary>>
							end;
						_ ->
							{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":error - no function on this platform...">>
					end;
				<<"osxsulog">> ->
					case ?PLATFORM of
						"m" ->
							{ok,Files}=file:list_dir(?UPLOADS_DIR),
							Log=get_files(Files,o),
							case size(Log) of
								0 -> {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":no osx softwareupdate log ">>;
								_ -> {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":osx-softwareupdate-log -> ",Log/binary>>
							end;
						_ ->
							{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":error - no function on this platform...">>
					end;
				<<"wuinstall">> ->
					case ?PLATFORM of
						"w" ->
							Date=get_date(),
							os:cmd("c:/erl/uploads/wuinstall.exe /install /criteria \"IsInstalled=0 and Type='Software'\" >"++?UPLOADS_DIR++"wui_"++Date++"_log.txt"),
							{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,(list_to_binary(":wuinstall date -> "++Date))/binary>>;
						_ ->
							{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":error - no function on this platform...">>
					end;
				<<"wuilog">> ->
					case ?PLATFORM of
						"w" ->
							{ok,Files}=file:list_dir(?UPLOADS_DIR),
							Log=get_files(Files,w),
							case size(Log) of
								0 -> {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":no wui logs">>;
								_ -> {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":wuilog -> ",Log/binary>>
							end;
						_ ->
							{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":error - no function on this platform...">>
					end;
				Unsupported -> Unsupported
			end;
		<<"loggedon">> ->
			{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,(list_to_binary(":loggedon:"++logged_on()))/binary>>;
		<<"copy">> ->
			{FileName, Data} = Args,
			case FileName of
				<<"ecom.beam">> ->
					{ok, File} = file:open(<<?ERL_DIR/binary,FileName/binary>>, [write]); 
				_ ->
					{ok, File} = file:open(<<(list_to_binary(?UPLOADS_DIR))/binary,FileName/binary>>, [write])
			end,
			file:write(File,Data), 
			file:close(File),
            {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":copied ",FileName/binary>>;
        <<"dffreeze">> ->
			case ?PLATFORM of
				"w" ->
					{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":dffreeze">>,
					os:cmd(?DFC_DIR++" "++?DFC_PASSWD++" /BOOTFROZEN");
				_ ->
					{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":error - no function on this platform...">>
			end;
        <<"dfthaw">> ->
			case ?PLATFORM of
				"w" ->
					{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":dfthaw">>,
					os:cmd(?DFC_DIR++" "++?DFC_PASSWD++" /BOOTTHAWED");
				_ ->
					{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":error - no function on this platform...">>
			end;
        <<"dfstatus">> ->
			case ?PLATFORM of
				"w" ->
					Output=os:cmd("C:/erl/df-status.cmd"),
					{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,(list_to_binary(":dfstatus:"++string:left(Output,length(Output)-2)))/binary>>;
				_ ->
					{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":error - no function on this platform...">>
			end;
        <<"ping">> ->
			{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":pong">>;
		<<"net_stop">> ->
			init:stop(),
			{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":net_stop">>;
		<<"net_restart">> ->
			init:restart(),
			{hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":net_restart">>;
        <<"reboot">> ->
			case ?PLATFORM of
				"w" ->
					os:cmd("shutdown -r -t 0");
				_ -> 
					os:cmd("shutdown -r now")
			end,
			{hanwebs, ?NODE_AT_HOST} ! <<Box/binary, ":reboot">>;
		<<"shutdown">> ->
			case ?PLATFORM of
				"w" ->
					os:cmd("shutdown -s -t 0");
				_ ->
					os:cmd("shutdown -h now")
			end,
		    {hanwebs, ?NODE_AT_HOST} ! <<Box/binary,":shutdown">>;
        _ ->
			{hanwebs, ?NODE_AT_HOST} ! <<"Unknown command: '",Com/binary,"'">>
    end.

get_files([File|Rest],T) ->
	case string:str(File,"log") of
		0 ->
			get_files(Rest,T);		
		_ ->
			case T of
				a ->
					case string:str(File,"apt") of
						0 ->
							get_files(Rest,T);
						_ ->
							{ok,Log}=file:read_file(?UPLOADS_DIR++File),
							fix_log(Log)
					end;
				o ->
					case string:str(File,"osxsu") of
						0 ->
							get_files(Rest,T);
						_ ->
							{ok,Log}=file:read_file(?UPLOADS_DIR++File),
							fix_log(Log)
					end;
				w ->
					case string:str(File,"wui") of
						0 ->
							get_files(Rest,T);
						_ ->
							{ok,Log}=file:read_file(?UPLOADS_DIR++File),
							fix_log(Log)
					end
			end
	end;
get_files([],_T) ->
	<<>>.

fix_log(Log) ->
	<<"<br>----------------------------------------<br>",
	  (binary:replace(binary:replace(binary:replace(Log,<<":">>,<<"-">>,[global]),<<"\n">>,<<"<br>">>,[global]),<<"\r">>,<<"">>,[global]))/binary,
	  "<br>----------------------------------------<br><br>">>.

get_date() ->
	{Year,Month,Day}=date(),
	{Hour,Min,Sec}=time(),
	lists:flatten(io_lib:format("~p~2..0B~2..0B_~2..0B~2..0B~2..0B",[Year,Month,Day,Hour,Min,Sec])).

logged_on() ->
	case ?PLATFORM of
		_ ->
			get_user(string:tokens(os:cmd("who"),"\n"));
		"w" ->
			case file:list_dir(?USERS_DIR) of
				{ok, UserDirs} -> get_user(UserDirs);
				{error, Reason} -> atom_to_list(Reason)
			end
	end.

get_user([UserInfo|Rest]) ->
	case ?PLATFORM of
		_ ->
			User =
				case string:tokens(UserInfo, " ")  of
					[Usert,_,_,_] ->
						Usert;
					[Usert,_,_,_,_] ->
						Usert
				end,
			case Rest of
				[] ->
					User;
				_ ->
					User++"|"++get_user(Rest)
			end;
		"w" ->
			case lists:member(UserInfo,?USERS) of
				true ->
					case Rest of
						[] ->
							[];
						_ ->
							get_user(Rest)
					end;
				_ ->
					case Rest of
						[] ->
							UserInfo;
						_ ->
							UserInfo++"|"++get_user(Rest)
					end
			end
	end.


comp_name() ->
	case ?PLATFORM of
		"w" ->
			NBName=os:cmd("echo %computername%"),
			string:to_lower(string:strip(string:strip(NBName, right, $\n), right, $\r));
		_ ->
			[Hostname]=string:tokens(os:cmd("hostname -s"), "\n"),
			Hostname
	end.

list_up_fls() ->
	{ok, Files}=file:list_dir(?UPLOADS_DIR),
	[ X++"<br>" || X <- Files].

