%%--------------------------------------------------------------------
%% Copyright (c) 2019 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(ekka_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok, {{one_for_all, 0, 3600},
          [child(ekka_cluster_sup, supervisor),
           child(ekka_membership, worker),
           child(ekka_node_monitor, worker),
           child(ekka_locker_sup, supervisor)
          ]}}.

child(Mod, worker) ->
    #{id       => Mod,
      start    => {Mod, start_link, []},
      restart  => permanent,
      shutdown => 5000,
      type     => worker,
      modules  => [Mod]};

child(Mod, supervisor) ->
     #{id       => Mod,
       start    => {Mod, start_link, []},
       restart  => permanent,
       shutdown => infinity,
       type     => supervisor,
       modules  => [Mod]}.

