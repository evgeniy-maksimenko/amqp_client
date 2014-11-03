-module(consumer_worker).
-behaviour(gen_server).
-include_lib("amqp_client/include/amqp_client.hrl").
-export([start_link/1]).

-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-export([receive_logs_direct/1]).

-define(SERVER, ?MODULE).
-record(state, {channel}).

start_link(Channel) ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [Channel], []).

init([Channel]) ->
  {ok, #state{channel=Channel}}.
%% =====================================================================================================================
%% API
%% =====================================================================================================================

receive_logs_direct(Argv)->
  gen_server:cast(?MODULE, {receive_logs_direct,Argv}).

%% =====================================================================================================================
%% Callbacks
%% =====================================================================================================================
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast({receive_logs_direct, Argv}, State) ->
  amqp_channel:call(State#state.channel, #'exchange.declare'{exchange = <<"direct_logs">>, type = <<"direct">>}),

  #'queue.declare_ok'{queue = Queue} =
    amqp_channel:call(State#state.channel, #'queue.declare'{exclusive = true}),

  [amqp_channel:call(State#state.channel, #'queue.bind'{exchange = <<"direct_logs">>,routing_key = list_to_binary(Severity), queue = Queue})  || Severity <- Argv],

  io:format(" [*] Waiting for messages. To exit press CTRL+C~n"),

  amqp_channel:subscribe(State#state.channel, #'basic.consume'{queue = Queue, no_ack = true}, self()),
  receive
    #'basic.consume_ok'{} -> ok
  end,
  loop(State#state.channel),
  {noreply, State};
handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

loop(Channel) ->
  receive
    {#'basic.deliver'{routing_key = RoutingKey}, #amqp_msg{payload = Body}} ->
      io:format(" [x] Received ~p:~p~n", [RoutingKey, Body]),
      loop(Channel)
  end.

