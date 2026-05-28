%%%-------------------------------------------------------------------
%%% @doc Linuxfr Atom filter application.
%%%
%%% Responsibility:
%%%   - copy priv/atom_config.json to working directory
%%%   - start atom_filter application
%%%
%%% atom_filter handles em_filter internally.
%%%-------------------------------------------------------------------
-module(linuxfr_atom_filter_app).

-behaviour(application).

-export([start/2, stop/1]).
-export([handle/2, base_capabilities/0]).

%%====================================================================
%% Application lifecycle
%%====================================================================

start(_Type, _Args) ->
    copy_config(),
    case linuxfr_atom_filter_sup:start_link() of
        {ok, Pid} ->
            ok = start_pop_and_http(),
            {ok, Pid};
        Error ->
            Error
    end.

stop(_State) ->
    catch cowboy:stop_listener(linuxfr_atom_filter_query_listener),
    catch em_pop_sup:stop_node(linuxfr_atom_filter),
    ok.

%%====================================================================
%% Capabilities and handler
%%====================================================================

-spec base_capabilities() -> [binary()].
base_capabilities() ->
    atom_filter_app:base_capabilities() ++ [<<"linuxfr">>, <<"linux">>, <<"opensource">>, <<"french">>].

-spec handle(binary(), map()) -> {list(), map()}.
handle(Body, Memory) ->
    atom_filter_app:handle(Body, Memory).

%%====================================================================
%% Internal
%%====================================================================

start_pop_and_http() ->
    PopPort   = application:get_env(linuxfr_atom_filter, pop_port,   9460),
    QueryPort = application:get_env(linuxfr_atom_filter, query_port, 9461),
    Seeds     = application:get_env(linuxfr_atom_filter, pop_seeds,  []),
    Vec = em_filter_vec:from_capabilities(base_capabilities()),
    catch em_pop_sup:stop_node(linuxfr_atom_filter),
    catch cowboy:stop_listener(linuxfr_atom_filter_query_listener),
    {ok, PopPid} = em_pop_sup:start_node(linuxfr_atom_filter, #{
        port            => PopPort,
        query_port      => QueryPort,
        vector          => Vec,
        max_peers       => 100,
        gossip_interval => 5_000
    }),
    lists:foreach(
        fun({H, P}) -> catch em_pop_node:add_peer(PopPid, H, P) end,
        Seeds),
    Dispatch = cowboy_router:compile([
        {'_', [{"/agent/query", em_filter_http,
                #{server => linuxfr_atom_filter_server}}]}
    ]),
    {ok, _} = cowboy:start_clear(linuxfr_atom_filter_query_listener,
                                  [{port, QueryPort}],
                                  #{env => #{dispatch => Dispatch}}),
    logger:notice("[linuxfr_atom_filter] gossip port ~w  query port ~w",
                  [PopPort, QueryPort]),
    ok.

copy_config() ->
    case code:priv_dir(linuxfr_atom_filter) of

        %% running in release
        PrivDir when is_list(PrivDir) ->
            Src = filename:join(PrivDir, "atom_config.json"),
            file:copy(Src, "atom_config.json"),
            ok;

        %% running in dev mode
        {error, bad_name} ->
            ok
    end.
