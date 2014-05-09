-module(element_textbox).
-author('Rusty Klophaus').
-include_lib("n2o/include/wf.hrl").
-compile(export_all).

reflect() -> record_info(fields, textbox).

render_element(Record) -> 
    List = [
      {<<"id">>, Record#textbox.id},
      {<<"type">>, Record#textbox.type},
      {<<"maxlength">>,Record#textbox.maxlength},
      {<<"style">>,Record#textbox.style},
      {<<"name">>,Record#textbox.html_name},
      {<<"placeholder">>,Record#textbox.placeholder},
      {<<"value">>,Record#textbox.value},
      {<<"class">>,Record#textbox.class} | Record#textbox.data_fields
  ],
  wf_tags:emit_tag(<<"input">>, wf:render(Record#textbox.body), List).

