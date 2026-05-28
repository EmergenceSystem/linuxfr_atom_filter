%%%-------------------------------------------------------------------
%%% @doc linuxfr_atom_filter supervisor.
%%%
%%% Supervises the linuxfr_atom_filter_server gen_server.
%%% @end
%%%-------------------------------------------------------------------
-module(linuxfr_atom_filter_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    ServerSpec = #{
        id      => linuxfr_atom_filter_server,
        start   => {linuxfr_atom_filter_server, start_link, []},
        restart => permanent,
        type    => worker
    },
    {ok, {#{strategy => one_for_one, intensity => 3, period => 10},
          [ServerSpec]}}.
