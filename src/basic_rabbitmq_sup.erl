%%%-------------------------------------------------------------------
%% @doc basic_rabbitmq top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(basic_rabbitmq_sup).

-behaviour(supervisor).

-export([start_link/2]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link(Connection, Channel) ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, [Connection, Channel]).

init([Connection, Channel]) ->
    SupFlags = #{strategy => one_for_all,
                 intensity => 0,
                 period => 1},
    ChildSpecs = [
        #{
            id => sender,
            start => {sender, start_link, [Connection, Channel]},
            restart => permanent,
            type => worker,
            modules => [sender]
        },
        #{
            id => receiver,
            start => {receiver, start_link, [Connection, Channel]},
            restart => permanent,
            type => worker,
            modules => [receiver]
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.
