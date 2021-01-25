%%%-------------------------------------------------------------------
%%% @author joegoodwin
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. Jan 2021 11:40
%%%-------------------------------------------------------------------
-module(receiver).
-author("joegoodwin").
-include_lib("/Users/joegoodwin/git/basic-rabbitmq/_build/default/lib/amqp_client/include/amqp_client.hrl").

-behaviour(gen_server).

%% API
-export([start_link/2]).

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


%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([Connection, Channel]) ->
	Method = #'basic.consume'{queue = ?QUEUE_NAME, no_ack = true},
	amqp_channel:subscribe(Channel, Method, self()),
	{ok, #client_state{connection = Connection, channel = Channel}}.

handle_call(_Request, _From, State = #client_state{}) ->
	{reply, ok, State}.

handle_cast(_Request, State = #client_state{}) ->
	{noreply, State}.

handle_info(Info, State = #client_state{}) ->
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

code_change(_OldVsn, State = #client_state{}, _Extra) ->
	{ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
