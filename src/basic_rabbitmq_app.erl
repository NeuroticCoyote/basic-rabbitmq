%%%-------------------------------------------------------------------
%% @doc basic_rabbitmq public API
%% @end
%%%-------------------------------------------------------------------

-module(basic_rabbitmq_app).

-behaviour(application).

-include_lib("/Users/joegoodwin/git/basic-rabbitmq/_build/default/lib/amqp_client/include/amqp_client.hrl").


-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    application:ensure_started(amqp_client),
    {ok, Connection} = amqp_connection:start(#amqp_params_network{host = "localhost"}),
    {ok, Channel} = amqp_connection:open_channel(Connection),
    basic_rabbitmq_sup:start_link(Connection, Channel).

stop(_State) ->
    ok.