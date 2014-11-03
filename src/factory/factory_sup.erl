-module(factory_sup).
-behaviour(supervisor).
-include_lib("amqp_client/include/amqp_client.hrl").
-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  Flags = {one_for_one, 5, 10},

  {ok, Connection} =
    amqp_connection:start(#amqp_params_network{host = "localhost"}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  ProducerWork = {producer_worker, {producer_worker, start_link, [Channel,Connection]}, permanent, 10500, supervisor, [producer_worker]},
  ConsumerWork = {consumer_worker, {consumer_worker, start_link, [Channel]}, permanent, 10500, supervisor, [consumer_worker]},

  {ok, { Flags , [ProducerWork, ConsumerWork]} }.

