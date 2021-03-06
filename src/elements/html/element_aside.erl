-module(element_aside).
-include_lib("n2o/include/wf.hrl").
-compile(export_all).

reflect() -> record_info(fields, aside).

render_element(Record) ->
    wf_tags:emit_tag(aside, Record#aside.body, [
        {id, Record#aside.id},
        {class, ["aside", Record#aside.class]},
        {style, Record#aside.style}
    ]).
