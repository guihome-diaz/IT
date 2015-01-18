$(document).ajaxError(
    function (event, jqXHR, ajaxSettings, thrownError) {
        alert('[event:' + event + '], [jqXHR:' + jqXHR + '], [ajaxSettings:' + ajaxSettings + '], [thrownError:' + thrownError + '])');
});

// Script initialization
// The following method is called when the page is first loaded.
$(document).ready(function() {
	
	$("#submitMediaWikiBackup").click(function() {
		// Ajax request
		$.ajax({ 
			type: "POST",
			// request settings (put the server script URL 'backup_wiki.php')
			url: '.../backup_wiki.php',			
	      	// Set timeout (in ms) before error 
			timeout: 300000,
			crossDomain: true,
			cache: false,
			beforeSend: function() {
				$(".modal").slideToggle();
			},
			success: function(response) {
				$('#scriptResult').html(response);
				$('#scriptResult').fadeIn();
				$('.successPanel').fadeIn();
			},
			error: function(request, errorType, errorMessage) { 
				$('.errorPanel').fadeIn();
				$('#scriptResult').html("Error, something went wrong!<br>Error type: " + errorType + "<br>Error message: " + errorMessage).fadeIn();
			},
			complete: function() {
				$(".modal").slideToggle();
			}
	    });	
	});	
});
