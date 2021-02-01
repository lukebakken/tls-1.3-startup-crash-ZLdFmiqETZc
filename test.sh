#!/usr/bin/env escript
%% -*- erlang -*-
%%! -smp enable -sname ERL539
main(_) ->
    try
        start()
    catch
        ErrT:Err ->
			io:format("[ERROR] ~p : ~p~n", [ErrT, Err]),
            usage()
    end;
main(_) ->
    usage().

usage() ->
    io:format("usage: repro\n"),
    halt(1).

start() ->
   ssl:start(),
   server(4000).

server(Port) ->
	Opts = [
		{cacertfile, "/FOOBAR/home/lbakken/development/michaelklishin/tls-gen/basic/result/ca_certificate.pem"},
		{certfile, "/home/lbakken/development/michaelklishin/tls-gen/basic/result/server_certificate.pem"},
		{keyfile, "/home/lbakken/development/michaelklishin/tls-gen/basic/result/server_key.pem"},
		{reuseaddr, true},
		{active, false}
	],
    {ok, LSocket} = ssl:listen(Port, Opts),
    accept(LSocket).
    
accept(LSocket) ->
   {ok, Socket} = ssl:transport_accept(LSocket),
   F = fun() ->
               try
                   ok = ssl:ssl_accept(Socket)
               catch
                   ErrT:Err ->
                       io:format("[ERROR] ssl:ssl_accept ~p : ~p~n", [ErrT, Err])
               end,
               io:format("Connection accepted ~p~n", [Socket]),
               loop(Socket)
       end,
   Pid = spawn(F),
   ssl:controlling_process(Socket, Pid),
   accept(LSocket).

loop(Socket) ->
   ssl:setopts(Socket, [{active, once}]),
   receive
   {ssl,Sock, Data} ->
        io:format("Got packet: ~p~n", [Data]),
        ssl:send(Sock, Data),
        loop(Socket);
   {ssl_closed, Sock} ->
        io:format("Closing socket: ~p~n", [Sock]);
   Error ->
        io:format("Error on socket: ~p~n", [Error])
   end.
