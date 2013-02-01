$(document).ready(function(){
  $('input.action').click( function() {
    takeAction($(this));
  });

  // activate the current tab  
  $('a[href="'+window.location.pathname+'"]').parent().addClass("ui-tabs-selected ui-state-active");
});

function takeAction(button) {
  var action   = button.attr("name");
  var certname = button.attr("param");
  var message  = "Are you sure you want to " + action + " " + certname + "?"
  
  if(confirm(message))
  {
    switch(action) {
      case 'sign':
        var uri   = '/sign/'+certname;
        var state = {
           "name": "revoke",
          "value": "Revoke",
          "class": ""
        }
        break;
        
      case 'revoke':
        var uri   = '/revoke/'+certname;
        var state = {
           "name": "clean",
          "value": "Clean",
          "class": "destructive"
        }
        break;

      case 'clean':
        var uri   = '/clean/'+certname;
        var state = { "hidden": true }

        break;
      
      default:
        throw("Invalid Action");
    }
      
    $.get(uri, function(data) {
      console.log(data);
      var results = jQuery.parseJSON(data);
      if(results.status == 'success') {
        if(state['hidden']) {
          button.parent().parent().hide();
        }
        else {
          button.prop("name", state['name']);
          button.prop("value", state['value']);
          button.addClass(state['class']);
        }
      }
      else {
        alert('Could not ' + action + ' certificate: ' + results.message)
      }
    });
  }
}