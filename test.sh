#!/usr/bin/env escript
%% -*- erlang -*-
%%! -smp enable -sname tls-test
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
    io:format("usage: test.sh\n"),
    halt(1).

start() ->
   ssl:start(),
   server(4000).

server(Port) ->
    Opts = [
        {cacertfile, "./certs/fullchain1.pem"},
        {certfile, "./certs/cert1.pem"},
        {keyfile, "./certs/privkey1.pem"},
        {secure_renegotiate, true},
        {client_renegotiation, true},
        %% NB this works:
        {versions, ['tlsv1.2','tlsv1.3']},
        %% NB this does not work:
        % {versions, ['tlsv1.3']},
        {reuseaddr, true},
        {active, false}
    ],
    {ok, LSocket} = ssl:listen(Port, Opts),
    accept(LSocket).
    
accept(LSocket) ->
   {ok, Socket} = ssl:transport_accept(LSocket),
   F = fun() ->
               try
                   ok = ssl:ssl_handshake(Socket)
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
