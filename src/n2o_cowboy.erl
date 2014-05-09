-module(n2o_cowboy).
-author('Roman Shestakov').
-behaviour(cowboy_http_handler).
-include_lib("n2o/include/wf.hrl").
-export([init/3, handle/2, terminate/3]).
-compile(export_all).
-record(state, {headers, body, opts}).

%% Cowboy HTTP Handler

init(_Transport, Req, Opts) ->
    {ok, Req, #state{opts = Opts}}.


terminate(_Reason, _Req, _State) -> ok.

handle(Req, State) ->
    Path = case wf:to_atom(string:strip(wf:to_list(path(Req)), both, $/)) of
               '' -> index;
               Other -> Other
           end,

    ?PRINT(Path),
    {ok, ReqFinal} =
        case host(Req) of
            {<<"dev.g10.web.all.all.gimme10.com">>, _Req} -> return_page(Req, get_module(g10, web, all, all, Path, State#state.opts));
                {<<"g10.web.all.all.gimme10.com">>, _Req} -> return_page(Req, get_module(g10, web, all, all, Path, State#state.opts));
            _ -> throw('error_404')

        %% old

        %{<<"dev.web.all.gimme10.com">>, _Req} -> return_page(Req, get_module(web,all,Path), State#state.opts);
        %{<<"web.all.gimme10.com">>, _Req}     -> return_page(Req, get_module(web,all,Path), State#state.opts);


        %% older

        %{<<"www-anon.10.0.1.20.xip.io">>, _Req} -> return_page(Req, get_module(www, anon, Path), State#state.opts);
        %{<<"www-anon.gimme10.com">>,_Req} -> return_page(Req, get_module(www, anon, Path), State#state.opts);
        %{<<"wwwangular-anon.gimme10.com">>, _Req} -> return_page(Req, get_module(wwwangular, anon, Path), State#state.opts);
        %{<<"webbusiness-owner.gimme10.com">>, _Req} -> return_page(Req, get_module(webbusiness, owner, Path), State#state.opts);

        end,
    {ok, ReqFinal, State}.

return_page(Req, {Module, Opts}) ->
    wf_context:page_module(Module),
    Elements = Module:main(Opts),
    Html = render(Elements),
    Req_ = response(Html, Req),
    reply(200, Req_).

get_module(g10, web, all, all, 'signup/g10_web_all_signup_all_signin_form', Opts) -> {g10_web_all_signup_all_signin_form, Opts};
get_module(g10, web, all, all, signup, Opts) -> {g10_web_all_signup_all, Opts};
get_module(g10, web, all, all, index, Opts) -> {g10_web_all_index_all, Opts}.

get_module(web, all, test) -> test;
get_module(web, all, signup) -> web_all_signup;
get_module(web, all, web_all_signup_templates_signin_form) -> web_all_signup_templates_signin_form;
get_module(web, all, _) -> web_all_index;

get_module(www, anon, signup) -> wwwangular_anon_index;
get_module(www, anon, _) -> www_anon_index;
get_module(wwwangular,anon, 'app/wwwangular/anon/pages/signup/index.erl') -> app_wwwangular_anon_pages_signup_index;
get_module(webbusiness, owner, _) ->  webbusiness_owner_index.


%% Cowboy Bridge Abstraction
%% CLEANUP: eliminating the need for simplebridge so these abstractions might not be necessary (although I'm using them as convenience functions here and there)

params(Req) -> {Params,_NewReq} = cowboy_req:qs_vals(Req), Params.
path(Req) -> {Path,_NewReq} = cowboy_req:path(Req), Path.
request_body(Req) -> cowboy_req:body(Req).
headers(Req) -> cowboy_req:headers(Req).
response(Html,Req) -> cowboy_req:set_resp_body(Html,Req).
reply(StatusCode,Req) -> cowboy_req:reply(StatusCode, Req).
cookies(Req) -> {Cookies,Req} = cowboy_req:cookies(Req), Cookies.
cookie(Cookie,Req) when is_atom(Cookie) -> cookie(list_to_binary(atom_to_list(Cookie)),Req);
cookie(Cookie,Req) -> {Val,_} = cowboy_req:cookie(Cookie,Req), Val.
cookie(Cookie, Value, Req) -> cookie(Cookie,Value,"/",0,Req).
cookie(Name, Value, Path, TTL, Req) ->
    Options = [{path, Path}, {max_age, TTL}],
    cowboy_req:set_resp_cookie(Name, Value, Options, Req).
delete_cookie(Cookie,Req) -> cookie(Cookie,"","/",0,Req).
peer(Req) -> {{Ip,Port},Req} = cowboy_req:peer(Req), {Ip,Port}.

host(Req) -> cowboy_req:host(Req).


%% copied from wf_core.erl
render_item(E) when element(2,E) == is_element -> wf_render_elements:render_element(E);
render_item(E) when element(2,E) == is_form -> wf_render_elements:render_element(E);
render_item(E) when element(2,E) == is_form_element -> wf_render_elements:render_element(E);
render_item(E) when element(2,E) == is_form_component -> wf_render_elements:render_element(E);
render_item(E) when element(2,E) == is_action  -> wf_render_actions:render_action(E);
render_item(E) -> E.
render(undefined) -> undefined;
render(Elements) when is_list(Elements) -> [ render_item(E) || E <- Elements ];
render(Elements) -> render_item(Elements).

%% CLEANUP: not needed because I've got rid of the wf context (except for saving the page_module to be used by the template)
                                                %fold(Fun,Handlers,Ctx) ->
                                                %  lists:foldl(fun({_,Module},Ctx) ->
                                                %    {ok,_,NewCtx} = Module:Fun([],Ctx),
                                                %    NewCtx end,Ctx,Handlers).
