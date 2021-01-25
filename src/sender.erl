%%%-------------------------------------------------------------------
%%% @author joegoodwin
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. Jan 2021 11:40
%%%-------------------------------------------------------------------
-module(sender).
-author("joegoodwin").
-include_lib("/Users/joegoodwin/git/basic-rabbitmq/_build/default/lib/amqp_client/include/amqp_client.hrl").

-behaviour(gen_server).

%% API
-export([start_link/2, send_message/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
	code_change/3]).

-define(SERVER, ?MODULE).

-define(QUEUE_NAME, <<"basic_rabbitmq_queue">>).

-record(client_state, {connection, channel}).

%%%===================================================================
%%% API
%%%===================================================================

start_link(Connection, Channel) ->
	gen_server:start_link({local, ?SERVER}, ?MODULE, [Connection, Channel], []).

send_message() ->
	gen_server:call(?SERVER, send_message).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([Connection, Channel]) ->
	amqp_channel:call(Channel, #'queue.declare'{queue = ?QUEUE_NAME}),
	{ok, #client_state{connection = Connection, channel = Channel}}.

handle_call(send_message, _From, State = #client_state{channel = Channel}) ->
	amqp_channel:cast(Channel,
		#'basic.publish'{
			exchange = <<"">>,
			routing_key = ?QUEUE_NAME},
		#amqp_msg{payload = <<"Hello World!">>}),
	io:format(" [x] Sent 'Hello World!'"),
	{reply, ok, State};
handle_call(_Request, _From, State = #client_state{}) ->
	{reply, ok, State}.

handle_cast(_Request, State = #client_state{}) ->
	{noreply, State}.

handle_info(_Info, State = #client_state{}) ->
	{noreply, State}.

terminate(_Reason, _State = #client_state{}) ->
	ok.

code_change(_OldVsn, State = #client_state{}, _Extra) ->
	{ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
