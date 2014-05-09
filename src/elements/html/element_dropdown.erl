-module(element_dropdown).
-include_lib("n2o/include/wf.hrl").
-compile(export_all).

reflect() -> record_info(fields, dropdown).

render_element(Record) ->
  ID = Record#dropdown.id,
  case Record#dropdown.postback of
    undefined -> skip;
    Postback -> wf:wire(#event { type=change,
    target=ID,
    postback=Postback,
    delegate=Record#button.delegate }) end,



  wf_tags:emit_tag(<<"select">>, [], [
    {<<"id">>, Record#dropdown.id},
    {<<"class">>, Record#dropdown.class},
    {<<"style">>, Record#dropdown.style},
    {<<"name">>, Record#dropdown.html_name},
    {<<"data_fields">>, Record#dropdown.data_fields},
    {<<"disabled">>, case Record#dropdown.disabled of true -> <<"disabled">>; _-> undefined end},
    {<<"multiple">>, case Record#dropdown.multiple of true -> <<"multiple">>; _-> undefined end}
  ]).