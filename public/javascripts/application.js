// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function ctrl_enter(e, form){
	if (((e.keyCode == 13) || (e.keyCode == 10)) && (e.ctrlKey == true)) form.submit();
}