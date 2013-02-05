$(document).ready(function(){
  $('input#newparam').click( function() {
    addParam($('table.parameters'));
  });

  // activate the current tab  
  $('a[href="'+window.location.pathname+'"]').parent().addClass("ui-tabs-selected ui-state-active");
});

function addParam(table) {
  param = prompt('Enter the name of the new parameter','ParamName');
  if (param != null && param != "") {
    label='<label for="param_' + param +'">' + param + '</label>'
    input='<input type="text" class="value" size="100" name="param_' + param + '" value="">'
    table.append('<tr class="unsaved"><td>' + label + '</td><td>' + input + '</td></tr>');
  }
}

