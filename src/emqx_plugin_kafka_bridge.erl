%%%-----------------------------------------------------------------------------
%%% Copyright (c) 2016 Huang Rui<vowstar@gmail.com>, All Rights Reserved.
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in all
%%% copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%%% SOFTWARE.
%%%-----------------------------------------------------------------------------
%%% @doc
%%% emqttd_plugin_kafka_bridge.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(emqx_plugin_kafka_bridge).


-include_lib("emqx/include/emqx.hrl").

%%-include("../../../include/emqttd.hrl").
%%-include("../../../include/emqttd_protocol.hrl").
%%-include("../../../include/emqttd_internal.hrl").

-export([load/1, unload/0]).

%% Hooks functions
-export([on_client_connect/3
  , on_client_connected/3
  , on_client_disconnected/4
  , on_client_subscribe/4
  , on_client_unsubscribe/4]).

-define(APP, emqx_plugin_kafka_bridge).

-export([on_message_publish/2, on_message_delivered/3, on_message_acked/3]).

%%-record(struct, {lst = []}).

%% Called when the plugin application start
load(Env) ->
  ekaf_init([Env]),
  emqx:hook('client.connect', {?MODULE, on_client_connect, [Env]}),
%%  emqx:hook('client.connack', {?MODULE, on_client_connack, [Env]}),
  emqx:hook('client.connected', {?MODULE, on_client_connected, [Env]}),
  emqx:hook('client.disconnected', {?MODULE, on_client_disconnected, [Env]}),
%%  emqx:hook('client.authenticate', {?MODULE, on_client_authenticate, [Env]}),
%%  emqx:hook('client.check_acl', {?MODULE, on_client_check_acl, [Env]}),
  emqx:hook('client.subscribe', {?MODULE, on_client_subscribe, [Env]}),
  emqx:hook('client.unsubscribe', {?MODULE, on_client_unsubscribe, [Env]}),
%%  emqx:hook('session.created', {?MODULE, on_session_created, [Env]}),
%%  emqx:hook('session.subscribed', {?MODULE, on_session_subscribed, [Env]}),
%%  emqx:hook('session.unsubscribed', {?MODULE, on_session_unsubscribed, [Env]}),
%%  emqx:hook('session.resumed', {?MODULE, on_session_resumed, [Env]}),
%%  emqx:hook('session.discarded', {?MODULE, on_session_discarded, [Env]}),
%%  emqx:hook('session.takeovered', {?MODULE, on_session_takeovered, [Env]}),
%%  emqx:hook('session.terminated', {?MODULE, on_session_terminated, [Env]}),
  emqx:hook('message.publish', {?MODULE, on_message_publish, [Env]}),
  emqx:hook('message.delivered', {?MODULE, on_message_delivered, [Env]}),
  emqx:hook('message.acked', {?MODULE, on_message_acked, [Env]}).
%%  emqx:hook('message.dropped', {?MODULE, on_message_dropped, [Env]}).


%%-----------client connect start-----------------------------------%%

on_client_connected(ClientInfo = #{clientid := ClientId}, ConnInfo, _Env) ->
  io:format("Client(~s) connected, ClientInfo:~n~p~n, ConnInfo:~n~p~n",
    [ClientId, ClientInfo, ConnInfo]),

  Json = [
    {type, <<"connected">>},
    {client_id, "ClientId"},
    {cluster_node, "1ddd"}
%%    {ts, erlang:timestamp()}
  ],

%%  ekaf:produce_async_batched(<<"broker_message">>, list_to_binary(Json)),

  produce_kafka_payload(Json),
  {ok, ClientInfo}.

on_client_connect(ConnInfo = #{clientid := ClientId}, Props, _Env) ->
  io:format("Client(~s) connect, ConnInfo: ~p, Props: ~p~n",
    [ClientId, ConnInfo, Props]),
  {ok, Props}.

%%-----------client connect end-------------------------------------%%

%%-----------client disconnect start---------------------------------%%

on_client_disconnected(ClientInfo = #{clientid := ClientId}, ReasonCode, ConnInfo, _Env) ->
  io:format("Client(~s) disconnected due to ~p, ClientInfo:~n~p~n, ConnInfo:~n~p~n", [ClientId, ReasonCode, ClientInfo, ConnInfo]),

  Json = [
    {type, <<"disconnected">>},
    {client_id, ClientId},
    {reason, ReasonCode},
    {cluster_node, node()},
    {ts, erlang:timestamp()}
  ],

  produce_kafka_payload(Json),

  ok.

%%-----------client disconnect end-----------------------------------%%


%%-----------client subscribed start---------------------------------------%%
%%on_client_subscribe(#{clientid := ClientId}, _Properties, TopicFilters, _Env) ->
%%  io:format("Client(~s) will subscribe: ~p~n", [ClientId, TopicFilters]),
%%  {ok, TopicFilters}.

%% should retain TopicTable
on_client_subscribe(#{clientid := ClientId}, _Properties, TopicTable, _Env) ->
  io:format("Client(~s) will subscribe: ~p~n", [ClientId, TopicTable]),

  case TopicTable of
    [_ | _] ->
      %% If TopicTable list is not empty
      Key = proplists:get_keys(TopicTable),
      %% build json to send using ClientId
      Json = mochijson2:encode([
        {type, <<"subscribed">>},
        {client_id, ClientId},
        {topic, lists:last(Key)},
        {cluster_node, node()},
        {ts, erlang:timestamp()}
      ]),
      ekaf:produce_async_batched(<<"broker_message">>, list_to_binary(Json));
    _ ->
      %% If TopicTable is empty
      io:format("empty topic ~n")
  end,

  {ok, TopicTable}.

%%-----------client subscribed end----------------------------------------%%


%%-----------client unsubscribed start----------------------------------------%%
%%on_client_unsubscribe(#{clientid := ClientId}, _Properties, TopicFilters, _Env) ->
%%  io:format("Client(~s) will unsubscribe ~p~n", [ClientId, TopicFilters]),
%%  {ok, TopicFilters}.

on_client_unsubscribe(#{clientid := ClientId}, _Properties, Topics, _Env) ->
  io:format("client ~s unsubscribe ~p~n", [ClientId, Topics]),

  % build json to send using ClientId
  Json = mochijson2:encode([
    {type, <<"unsubscribed">>},
    {client_id, ClientId},
    {topic, lists:last(Topics)},
    {cluster_node, node()},
    {ts, erlang:timestamp()}
  ]),

  ekaf:produce_async_batched(<<"broker_message">>, list_to_binary(Json)),

  {ok, Topics}.

%%-----------client unsubscribed end----------------------------------------%%


%%-----------message publish start--------------------------------------%%

%% transform message and return
on_message_publish(Message = #message{topic = <<"$SYS/", _/binary>>}, _Env) ->
  {ok, Message};

on_message_publish(Message, _Env) ->
  io:format("publish ~s~n", [emqx_message:format(Message)]),

  From = Message#message.from,
  Id = Message#message.id,
  Topic = Message#message.topic,
  Payload = Message#message.payload,
  QoS = Message#message.qos,
  Flags = Message#message.flags,
%%  Headers = Message#message.headers,
  Timestamp = Message#message.timestamp,

  Json = [
    {id, Id},
    {type, <<"published">>},
    {client_id, From},
    {topic, Topic},
    {payload, Payload},
    {qos, QoS},
    {flags, Flags},
%%    {headers, Headers},
    {cluster_node, node()},
    {ts, Timestamp}
  ],

  io:format("publish ~w~n", [Json]),

  produce_kafka_payload(Json),
%%  ekaf:produce_async_batched(<<"broker_message">>, list_to_binary(Json)),
  {ok, Message}.

%%-----------message delivered start--------------------------------------%%
on_message_delivered(_ClientInfo = #{clientid := ClientId}, Message, _Env) ->
  io:format("Message delivered to client(~s): ~s~n", [ClientId, emqx_message:format(Message)]),

  From = Message#message.from,
  Topic = Message#message.topic,
  Payload = Message#message.payload,
  QoS = Message#message.qos,
  Timestamp = Message#message.timestamp,

  Json = mochijson2:encode([
    {type, <<"delivered">>},
    {client_id, ClientId},
    {from, From},
    {topic, Topic},
    {payload, Payload},
    {qos, QoS},
    {cluster_node, node()},
    {ts, Timestamp}
  ]),

  ekaf:produce_async_batched(<<"broker_message">>, list_to_binary(Json)),

  {ok, Message}.
%%-----------message delivered end----------------------------------------%%

%%-----------acknowledgement publish start----------------------------%%
on_message_acked(_ClientInfo = #{clientid := ClientId}, Message, _Env) ->
  io:format("Message acked by client(~s): ~s~n", [ClientId, emqx_message:format(Message)]),

  From = Message#message.from,
  Topic = Message#message.topic,
  Payload = Message#message.payload,
  QoS = Message#message.qos,
  Timestamp = Message#message.timestamp,

  Json = mochijson2:encode([
    {type, <<"acked">>},
    {client_id, ClientId},
    {from, From},
    {topic, Topic},
    {payload, Payload},
    {qos, QoS},
    {cluster_node, node()},
    {ts, Timestamp}
  ]),

  ekaf:produce_async_batched(<<"broker_message">>, list_to_binary(Json)),
  {ok, Message}.

%% ===================================================================
%% ekaf_init
%% ===================================================================

ekaf_init(_Env) ->

  application:set_env(ekaf, ekaf_partition_strategy, strict_round_robin),
  application:set_env(ekaf, ekaf_bootstrap_broker, {"192.168.1.106", 9092}),
  application:set_env(ekaf, ekaf_bootstrap_topics, "broker_message"),
  %%设置数据上报间隔，ekaf默认是数据达到1000条或者5秒，触发上报
  application:set_env(ekaf, ekaf_buffer_ttl, 100),
  io:format("Init ekaf with ~s~n", ["==== TTTTTT ====="]),
  {ok, _} = application:ensure_all_started(ekaf).

%Json = mochijson2:encode([
%    {type, <<"connected">>},
%    {client_id, <<"test-client_id">>},
%    {cluster_node, <<"node">>}
%]),
%io:format("send : ~w.~n",[ekaf:produce_async_batched(list_to_binary(Topic), list_to_binary(Json))]).


%%ekaf_send(Message, _Env) ->
%%  From = Message#message.from,
%%  Topic = Message#message.topic,
%%  Payload = Message#message.payload,
%%  Qos = Message#message.qos,
%%  ClientId = get_form_clientid(From),
%%  Username = get_form_username(From),
%%  io:format("message receive : ~n",[]),
%%  io:format("From : ~w~n",[From]),
%%  io:format("Topic : ~w~n",[Topic]),
%%  io:format("Payload : ~w~n",[Payload]),
%%  io:format("Qos : ~w~n",[Qos]),
%%  io:format("ClientId : ~w~n",[ClientId]),
%%  io:format("Username : ~w~n",[Username]),
%%  Str = [
%%    {client_id, ClientId},
%%    {message, [
%%      {username, Username},
%%      {topic, Topic},
%%      {payload, Payload},
%%      {qos, Qos}
%%    ]},
%%    {cluster_node, node()},
%%    {ts, emqttd_time:now_ms()}
%%  ],
%%  io:format("Str : ~w.~n", [Str]),
%%  Json = mochijson2:encode(Str),
%%  KafkaTopic = get_topic(),
%%  ekaf:produce_sync_batched(KafkaTopic, list_to_binary(Json)).

%%get_form_clientid(From) -> From.
%%get_form_username(From) -> From.

%%get_topic() ->
%%  {ok, Topic} = application:get_env(ekaf, ekaf_bootstrap_topics),
%%  Topic.

ekaf_get_topic() ->
  {ok, Topic} = application:get_env(ekaf, ekaf_bootstrap_topics),
  Topic.

produce_kafka_payload(Message) ->
  Topic = ekaf_get_topic(),


  io:format("Squallfeng TEST~s~n",["produce_kafka_payload"]),

%%  io:format("~w~n",[jiffy:decode(Message)]),

  {ok, MessageBody} = emqx_json:safe_encode(Message),

%%  % MessageBody64 = base64:encode_to_string(MessageBody),
  Payload = list_to_binary(MessageBody),
  io:format("Squallfeng TEST~s~n",[Payload]),

  ekaf:produce_async_batched(Topic, Payload).

%% Called when the plugin application stop
unload() ->
  emqx:unhook('client.connect', {?MODULE, on_client_connect}),
  emqx:unhook('client.connected', {?MODULE, on_client_connected}),
  emqx:unhook('client.disconnected', {?MODULE, on_client_disconnected}),
  emqx:unhook('client.subscribe', {?MODULE, on_client_subscribe}),
  emqx:unhook('client.unsubscribe', {?MODULE, on_client_unsubscribe}),
  emqx:unhook('message.publish', {?MODULE, on_message_publish}),
  emqx:unhook('message.delivered', {?MODULE, on_message_delivered}),
  emqx:unhook('message.acked', {?MODULE, on_message_acked}).

