%%%-------------------------------------------------------------------
%%% @author joegoodwin
%%% @copyright (C) 2021
%%% @doc
%%%
%%% @end
%%% Created : 25. Jan 2021 11:40
%%%-------------------------------------------------------------------
-module(receiver).
-author("joegoodwin").
-include_lib("amqp_client/include/amqp_client.hrl").

-behaviour(gen_server).

%% API
-export([start_link/2,
	subscribe/1]).

%% gen_server callbacks
-export([init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3]).

-define(SERVER, ?MODULE).
-define(DEFAULT_QUEUE, <<"basic_rabbitmq_queue">>).

-record(receiver_state, {connection, channel}).

%%%===================================================================
%%% API
%%%===================================================================

start_link(Connection, Channel) ->
	gen_server:start_link({local, ?SERVER}, ?MODULE, [Connection, Channel], []).

subscribe(QueueName) ->
	gen_server:call(?SERVER, {subscribe, QueueName}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([Connection, Channel]) ->
	subscribe(Channel, ?DEFAULT_QUEUE),
	{ok, #receiver_state{connection = Connection, channel = Channel}}.

handle_call({subscribe, QueueName}, _From, State = #receiver_state{channel = Channel}) ->
	subscribe(Channel, QueueName),
	{reply, ok, State};
handle_call(_Request, _From, State) ->
	{reply, ok, State}.

handle_cast(_Request, State) ->
	{noreply, State}.

handle_info(Info, State = #receiver_state{}) ->
	case Info of
		#'basic.consume_ok'{} ->
			io:format(" [x] Saw basic.consume_ok~n"),
			ok;
		{#'basic.deliver'{}, #amqp_msg{payload = Body}} ->
			io:format(" [x] Received ~p~n", [Body]),
			Body
	end,
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

subscribe(Channel, Queue) ->
	BinaryQueue = sender:to_binary(Queue),
	Method = #'basic.consume'{queue = BinaryQueue, no_ack = true},
	try
		amqp_channel:subscribe(Channel, Method, self())
	catch
		E:_R ->
			io:format("Error subscribing to queue ~p, since it hasnt been created. Error: ~p", [BinaryQueue, E])
	end.