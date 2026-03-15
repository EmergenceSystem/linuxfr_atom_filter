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

%%====================================================================
%% Application callbacks
%%====================================================================

start(_StartType, _StartArgs) ->
    copy_config(),
    application:ensure_all_started(atom_filter),
    {ok, self()}.

stop(_State) ->
    ok.

%%====================================================================
%% Internal
%%====================================================================

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
