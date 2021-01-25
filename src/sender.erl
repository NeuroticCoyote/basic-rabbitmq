%%%-------------------------------------------------------------------
%%% @author joegoodwin
%%% @copyright (C) 2021
%%% @doc
%%%
%%% @end
%%% Created : 25. Jan 2021 11:40
%%%-------------------------------------------------------------------
-module(sender).
-author("joegoodwin").
-include_lib("amqp_client/include/amqp_client.hrl").

-behaviour(gen_server).

%% API
-export([start_link/2,
	send_message/2,
	send_test_message/0,
	to_binary/1]).

%% gen_server callbacks
-export([init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3]).

-define(SERVER, ?MODULE).
-define(DEFAULT_QUEUE, <<"basic_rabbitmq_queue">>).

-record(sender_state, {connection, channel, topics = []}).

%%%===================================================================
%%% API
%%%===================================================================

start_link(Connection, Channel) ->
	gen_server:start_link({local, ?SERVER}, ?MODULE, [Connection, Channel], []).

send_message(QueueName, Message) ->
	gen_server:call(?SERVER, {send_message, QueueName, Message}).

send_test_message() ->
	gen_server:call(?SERVER, {send_message, ?DEFAULT_QUEUE, <<"Hello World!">>}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([Connection, Channel]) ->
	call(Channel, ?DEFAULT_QUEUE),
	{ok, #sender_state{connection = Connection, channel = Channel, topics = [?DEFAULT_QUEUE]}}.

handle_call({send_message, Queue, Message}, _From, State = #sender_state{channel = Channel, topics = Topics}) ->
	BinaryQueue = to_binary(Queue),
	BinaryMessage = to_binary(Message),
	UpdatedTopics =
		case lists:member(BinaryQueue, Topics) of
			true ->
				Topics;
			false ->
				call(Channel, BinaryQueue),
				lists:append([BinaryQueue], Topics)
		end,
	publish_message(Channel, BinaryQueue, BinaryMessage),
	io:format(" [x] Sent '~p' to Queue '~p'", [BinaryMessage, BinaryQueue]),
	{reply, ok, State#sender_state{topics = UpdatedTopics}};
handle_call(_Request, _From, State = #sender_state{}) ->
	{reply, ok, State}.

handle_cast(_Request, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

to_binary(Binary) when is_binary(Binary) ->
	Binary;
to_binary(Atom) when is_atom(Atom) ->
	atom_to_binary(Atom);
to_binary(List) when is_list(List) ->
	list_to_binary(List).

call(Channel, QueueName) ->
	amqp_channel:call(Channel, #'queue.declare'{queue = QueueName}).

publish_message(Channel, Queue, Message) ->
	amqp_channel:cast(Channel,
		#'basic.publish'{
			exchange = <<"">>,
			routing_key = Queue},
		#amqp_msg{payload = Message}).