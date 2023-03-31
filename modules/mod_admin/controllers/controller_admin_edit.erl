%% @author Marc Worrell <marc@worrell.nl>
%% @copyright 2009-2010 Marc Worrell, Arjan Scherpenisse
%% @doc Admin webmachine_controller.

%% Copyright 2009-2010 Marc Worrell, Arjan Scherpenisse
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

-module(controller_admin_edit).
-author("Marc Worrell <marc@worrell.nl>").

-export([resource_exists/2,
         previously_existed/2,
         moved_temporarily/2,
         is_authorized/2,
         event/2,
         filter_props/1,
         ensure_id/1
        ]).

-include_lib("controller_html_helper.hrl").

%% @todo Change this into "visible" and add a view instead of edit template.
is_authorized(ReqData, Context) ->
    ReqData1 = wrq:set_resp_header("X-Frame-Options", "SAMEORIGIN", ReqData),
    Context1 = z_admin_controller_helper:init_session(?WM_REQ(ReqData1, Context)),
    {Context2, Id} = ensure_id(Context1),
    z_acl:wm_is_authorized([{use, mod_admin}, {view, Id}], admin_logon, Context2).


resource_exists(ReqData, Context) ->
    {Context2, Id} = ensure_id(?WM_REQ(ReqData, Context)),
    case Id of
        undefined -> ?WM_REPLY(false, Context2);
        _N -> ?WM_REPLY(m_rsc:exists(Id, Context2), Context2)
    end.

previously_existed(ReqData, Context) ->
    {Context1, Id} = ensure_id(?WM_REQ(ReqData, Context)),
    IsGone = m_rsc_gone:is_gone(Id, Context1),
    ?WM_REPLY(IsGone, Context1).

moved_temporarily(ReqData, Context) ->
    {Context1, Id} = ensure_id(?WM_REQ(ReqData, Context)),
    redirect(m_rsc_gone:get_new_location(Id, Context1), Context1).

redirect(undefined, Context) ->
    ?WM_REPLY(false, Context);
redirect(Location, Context) ->
    ?WM_REPLY({true, Location}, Context).


html(Context) ->
    Id = z_context:get(id, Context),
    Blocks = z_notifier:foldr(#admin_edit_blocks{id=Id}, [], Context),
    Vars = [
            {id, Id},
            {blocks, lists:sort(Blocks)}
            | z_context:get_all(Context)
           ],
    Html = z_template:render(z_context:get(template, Context, {cat, "admin_edit.tpl"}), Vars, Context),
    z_context:output(Html, Context).


%% @doc Fetch the (numerical) page id from the request
ensure_id(Context) ->
    case z_context:get(id, Context) of
        N when is_integer(N) ->
            {Context, N};
        undefined ->
            try
                {ok, IdN} = m_rsc:name_to_id(z_context:get_q("id", Context), Context),
                {z_context:set(id, IdN, Context), IdN}
            catch
                _:_ -> {Context, undefined}
            end
    end.


%% @doc Handle the submit of the resource edit form
event(#submit{message=rscform} = Msg, Context) ->
    event(Msg#submit{message={rscform, []}}, Context);
event(#submit{message={rscform, Args}}, Context) ->
    Post = z_context:get_q_all_noz(Context),
    Props = filter_props(Post),
    Id = z_convert:to_integer(proplists:get_value("id", Props)),
    Props1 = proplists:delete("id", Props),
    CatBefore = m_rsc:p(Id, category_id, Context),
    Props2 = z_notifier:foldl(#admin_rscform{id=Id, is_a=m_rsc:is_a(Id, Context)}, Props1, Context),
    try
        {ok, _} = m_rsc:update(Id, Props2, Context),
        case proplists:is_defined("save_view", Post) of
            true ->
                % Save and proceed to the html representation of the page
                case proplists:get_value(view_location, Args) of
                    undefined ->
                        PageUrl = m_rsc:p(Id, page_url, Context),
                        z_render:wire({redirect, [{location, PageUrl}]}, Context);
                    Location ->
                        z_render:wire({redirect, [{location, Location}]}, Context)
                end;
            false ->
                case m_rsc:p(Id, category_id, Context) of
                    CatBefore ->
                        % Update some automatically generated or adapted fields
                        PagePath = filter_urldecode:urldecode(m_rsc:p(Id, page_path, Context), Context),
                        Context1 = z_render:set_value("field-name", m_rsc:p(Id, name, Context), Context),
                        Context2 = z_render:set_value("field-uri",  m_rsc:p(Id, uri, Context), Context1),
                        Context3 = z_render:set_value("field-page-path", PagePath, Context2),
                        Context4 = z_render:set_value("website",  m_rsc:p(Id, website, Context), Context3),
                        Context4a = set_value_slug(m_rsc:p(Id, title_slug, Context), Context4),
                        Context4b= z_render:set_value("visible_for", integer_to_list(m_rsc:p(Id, visible_for, Context)), Context4a),
                        Context4c = case m_rsc:p(Id, publication_start, Context4b) of
                            undefined ->
                                Context4b;
                            PubStart ->
                                Ymd = filter_date:date(PubStart, "Y-m-d", Context4b),
                                Hi = filter_date:date(PubStart, "H:i", Context4b),
                                C4c = z_render:set_value(" input[name='dt:ymd:0:publication_start']", Ymd, Context4b),
                                z_render:set_value(" input[name='dt:hi:0:publication_start']", Hi, C4c)
                        end,
                        Context5 = case z_convert:to_bool(m_rsc:p(Id, is_protected, Context)) of
                                       true ->  z_render:wire("delete-button", {disable, []}, Context4c);
                                       false -> z_render:wire("delete-button", {enable, []}, Context4c)
                                   end,
                        Title = z_trans:lookup_fallback(m_rsc:p(Id, title, Context5), Context5),
                        Context6 = z_render:growl([<<"Saved \"">>, Title, <<"\".">>], Context5),
                        case proplists:is_defined("save_duplicate", Post) of
                            true ->
                                % Show dialog with new title for duplicated page
                                z_render:wire({dialog_duplicate_rsc, [{id, Id}]}, Context6);
                            false ->
                                % Wire optional extra success actions
                                case proplists:get_all_values(on_success, Args) of
                                    [] ->
                                        Context6;
                                    OnSuccessActions->
                                        z_render:wire(OnSuccessActions, Context6)
                                end
                        end;
                    _CatOther ->
                        % Category changed, so we need a different edit form
                        z_render:wire({reload, []}, Context)
                end
        end
    catch
        throw:{error, duplicate_uri} ->
            z_render:growl_error("Error, duplicate uri. Please change the uri.", Context);
        throw:{error, duplicate_page_path} ->
            z_render:growl_error("Error, duplicate page path. Please change the uri.", Context);
        throw:{error, duplicate_name} ->
            z_render:growl_error("Error, duplicate name. Please change the name.", Context);
        throw:{error, eacces} ->
            z_render:growl_error("You don't have permission to edit this page.", Context);
        throw:{error, invalid_query} ->
            z_render:growl_error("Your search query is invalid. Please correct it before saving.", Context);
        throw:{error, Message} when is_list(Message); is_binary(Message) ->
            z_render:growl_error(Message, Context);
        X:Y ->
            Stacktrace = erlang:get_stacktrace(),
            lager:error("Rsc update error: ~p:~p stacktrace: ~p", [X, Y, Stacktrace]),
            z_render:growl_error("Something went wrong. Sorry.", Context)
    end;

%% Opts: rsc_id, div_id, edge_template
event(#postback{message={reload_media, Opts}}, Context) ->
    DivId = proplists:get_value(div_id, Opts),
    {Html, Context1} = z_template:render_to_iolist({cat, "_edit_media.tpl"}, Opts, Context),
    z_render:update(DivId, Html, Context1);

event(#sort{items=Sorted, drop={dragdrop, {object_sorter, Props}, _, _}}, Context) ->
    RscId     = proplists:get_value(id, Props),
    Predicate = proplists:get_value(predicate, Props),
    EdgeIds   = [ EdgeId || {dragdrop, EdgeId, _, _ElementId} <- Sorted ],
    m_edge:update_sequence_edge_ids(RscId, Predicate, EdgeIds, Context),
    Context;

%% Previewing the results of a query in the admin edit
event(#postback{message={query_preview, Opts}}, Context) ->
    DivId = proplists:get_value(div_id, Opts),
    try
        Q = search_query:parse_query_text(z_context:get_q("triggervalue", Context)),
        S = z_search:search({'query', Q}, Context),
        {Html, Context1} = z_template:render_to_iolist("_admin_query_preview.tpl", [{result,S}], Context),
        z_render:update(DivId, Html, Context1)
    catch
        _: {error, {Kind, Arg}} ->
            z_render:growl_error(["There is an error in your query: ", Kind, " - ", Arg], Context)
    end.

set_value_slug(undefined, Context) ->
    set_value_slug(<<>>, Context);
set_value_slug({trans, Tr}, Context) ->
    lists:foldl(
        fun({Lang, V}, Ctx) ->
            z_render:set_value(
                "title_slug--" ++ atom_to_list(Lang),
                V,
                Ctx)
        end,
        Context,
        Tr);
set_value_slug(Slug, Context) ->
    z_render:set_value("title_slug", Slug, Context).

%% @doc Remove some properties that are part of the postback
filter_props(Fs) ->
    Remove = [
              "triggervalue",
              "postback",
              "z_trigger_id",
              "z_pageid",
              "z_submitter",
              "trigger_value",
              "save_view",
              "save_duplicate",
              "save_stay"
             ],
    lists:foldl(fun(P, Acc) -> proplists:delete(P, Acc) end, Fs, Remove).
