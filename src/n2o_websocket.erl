-module(n2o_websocket).
-author('Maxim Sokhatsky').
-behaviour(cowboy_websocket_handler).
-include_lib("n2o/include/wf.hrl").
-export([init/3]).
-export([websocket_init/3, websocket_handle/3, websocket_info/3, websocket_terminate/3]).

init({tcp,http}, _Req, _Opt) -> {upgrade, protocol, cowboy_websocket}.

websocket_init(_Any, Req, _Opt) ->
    RequestBridge = simple_bridge:make_request(cowboy_request_bridge, Req),    
    ResponseBridge = simple_bridge:make_response(cowboy_response_bridge, RequestBridge),
    wf_context:init_context(RequestBridge,ResponseBridge),
    wf:log("~p",[RequestBridge:peer_ip()]),
    wf_core:call_init_on_handlers(),
    {ok, Req, undefined_state}.
websocket_handle({text,Data}, Req, State) ->
    error_logger:info_msg("Text Received ~p",[Data]),
    self() ! Data, 
    {ok, Req,State};
websocket_handle({binary,Info}, Req, State) -> 
    Pro = binary_to_term(Info,[safe]),
    Pickled = proplists:get_value(pickle,Pro),
    Linked = proplists:get_value(linked,Pro),
    Api = proplists:get_value(extras,Pro),
    error_logger:info_msg("Extras  ~p~n",[Api]),
    Depickled = wf_pickle:depickle(Pickled),
    error_logger:info_msg("Depickled  ~p~n",[Depickled]),
    case Api of
         <<"api">> -> {event_context,_,Args,_,_,_} = Depickled,
                  action_api:event(Args,Linked);
         _ ->  lists:map(fun({K,V})->put(K,V)end,Linked) end,
    error_logger:info_msg("Depickled  ~p~n",[Depickled]),
    case Depickled of
         {event_context,Module,Parameter,_,_,_} ->
              Res = Module:event(Parameter);
%              error_logger:info_msg("Event Result ~p~n",[Res]);
         _ -> error_logger:info_msg("Unknown Event") end,
    {ok,Render} = wf_render_actions:render_actions(wf_context:actions()), 
    wf_context:clear_actions(),
    error_logger:info_msg("Render: ~p~n",[Render]),
    error_logger:info_msg("Cookies: ~p~n",[wf:cookies()]),
    error_logger:info_msg("Session Data: ~p~n",[wf:session(id)]),
    error_logger:info_msg("Headers: ~p~n",[wf:headers()]),
    {reply,{binary,term_to_binary(lists:flatten(Render))}, Req, State};
websocket_handle(_Any, Req, State) -> {ok, Req, State}.
websocket_info(Pro, Req, State) ->
%    error_logger:info_msg("WSINFO: ~p",[Pro]),
    Res = case Pro of
         {flush,Actions} -> {ok,Render} = wf_render_actions:render_actions(Actions), 
%                        error_logger:info_msg("Render: ~p",[Render]),
                            term_to_binary(lists:flatten(Render));
          <<"N2O">> ->     error_logger:info_msg("N2O WS INIT ACK: ~p",[wf_context:page_module()]),
                          (wf_context:page_module()):event(init),
                         {ok,Render} = wf_render_actions:render_actions(wf_context:actions()), 
                            wf_context:clear_actions(),
                            term_to_binary(lists:flatten(Render));
          Unknown ->     error_logger:info_msg("Unknown: ~p",[Unknown]),
                           <<"OK">> 
                    end,
%    error_logger:info_msg("Res: ~p",[Res]),
    {reply, {binary,Res}, Req, State}.

websocket_terminate(_Reason, _Req, _State) -> 
    error_logger:info_msg("Terminate WS ~p~n",[_Reason]),
    ok.
