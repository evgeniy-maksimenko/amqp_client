-module(producer_worker).
-behaviour(gen_server).
-include_lib("amqp_client/include/amqp_client.hrl").
-export([start_link/2]).

-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-export([emit_log_direct/1]).

-define(SERVER, ?MODULE).
-record(state, {channel,connection}).

start_link(Channel,Connection) ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [Channel,Connection], []).

init([Channel,Connection]) ->
  {ok, #state{channel=Channel,connection=Connection}}.
%% =====================================================================================================================
%% API
%% =====================================================================================================================

emit_log_direct(Argv) ->
  gen_server:cast(?MODULE,{emit_log_direct, Argv}).

%% =====================================================================================================================
%% Callbacks
%% =====================================================================================================================
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast({emit_log_direct, Argv}, State) ->

  amqp_channel:call(State#state.channel, #'exchange.declare'{exchange = <<"direct_logs">>,
    type = <<"direct">>}),

  {Severity, Message} = case Argv of
                          [] ->
                            {<<"info">>, <<"Hello World!">>};
                          [S] ->
                            {list_to_binary(S), <<"Hello World!">>};
                          [S | Msg] ->
                            {list_to_binary(S), list_to_binary(string:join(Msg, " "))}
                        end,

  amqp_channel:cast(State#state.channel,
    #'basic.publish'{
      exchange = <<"direct_logs">>,
      routing_key = Severity},
    #amqp_msg{payload = Message}),

  io:format(" [x] Sent ~p:~p~n", [Severity, Message]),
  {noreply, State};
handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, State) ->
  ok = amqp_channel:close(State#state.channel),
  ok = amqp_connection:close(State#state.connection),
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

