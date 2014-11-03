-module(webserver_sup).
-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->

  FactorySup = {factory_sup, {factory_sup, start_link, []}, permanent, 10500, supervisor, [factory_sup]},
  Flags = {one_for_one, 5, 10},
  {ok, { Flags , [FactorySup]} }.

