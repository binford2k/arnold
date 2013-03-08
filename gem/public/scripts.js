$(document).ready(function(){
  $('input#newparam').click( function() {
    addParam($('table.parameters'));
  });

  // activate the current tab  
  $('a[href="'+window.location.pathname+'"]').parent().addClass("ui-tabs-selected ui-state-active");

  // confirm updates
  $('form#updateNode').submit(function(e) {
    var active = $(this).find("input[type='submit'].active");
    var action = active.attr('id');

    // remove the active class in case we cancel an action and need to run again
    active.removeClass('active');

    switch(action) {
      case 'deleteNode':
        return confirm("Click OK to continue?");
        break;
      case 'updateNode':
        return true;
        break;
      default:
        return false;
    }
  });

  // add a semaphore class so that the form handler knows which button we clicked.
  $('form#updateNode input[type="submit"]').click(function() {
    $(this).addClass('active');
  });
});

function addParam(table) {
  param = prompt('Enter the name of the new parameter','ParamName');
  if (param != null && param != "") {
    if ($('input#param_' + param).length == 0) {
      label='<label for="param_' + param +'">' + param + '</label>'
      input='<input type="text" class="value" size="100" name="param_' + param + '" id="param_' + param + '" value="">'
      table.append('<tr class="unsaved"><td>' + label + '</td><td>' + input + '</td></tr>');
      $('input#param_' + param).focus();
    }
  }
}

