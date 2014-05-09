-module (wf_render_elements).
-author('Rusty Klophaus').
-include_lib ("n2o/include/wf.hrl").
-compile(export_all).

render_element(E) when is_list(E) -> E;
render_element(Element) when is_tuple(Element) ->
    Base = wf_utils:get_elementbase(Element),
    Module = Base#elementbase.module,
    %case Base#elementbase.is_element == is_element of
    %    true -> ok;
    %    false -> throw({not_an_element, Element}) end,
    case Base#elementbase.show_if of
        false -> [];
        "" -> [];
        undefined -> [];
        0 -> [];
        _ -> ID = case Base#elementbase.id of
                       %undefined -> temp_id();
                       undefined -> [];
                       Other2 when is_atom(Other2) -> atom_to_list(Other2);
                       L when is_list(L) -> L end,
             Class = case Base#elementbase.class of
                      undefined -> [];
                      <<>> -> [];
                      "" -> [];
                      Other3 -> wf:to_binary(Other3)
                     end,
             Base1 = Base#elementbase { id=ID, class=Class },
             Element1 = wf_utils:replace_with_base(Base1, Element),
             wf:wire(Base1#elementbase.actions),
             NewElements = Module:render_element(Element1),
             wf_core:render(NewElements)
    end;
render_element(Element) -> error_logger:info_msg("Unknown Element: ~p",[Element]).

temp_id() ->{_, _, C} = now(), "temp" ++ integer_to_list(C).
