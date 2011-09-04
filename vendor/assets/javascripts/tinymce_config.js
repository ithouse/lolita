function load_tinymce(){
	$("textarea[data-simple!=true]").tinymce({
		script_url: "/javascripts/tinymce/tiny_mce.js",
		theme: "advanced",
		skin: "cirkuit",
		mode: "textareas",
		theme_advanced_buttons1 : "bold,italic,underline,|,justifyleft,justifycenter,justifyright,|,formatselect,|,link,unlink,image,code",
		theme_advanced_buttons2 : "",
		theme_advanced_buttons3 : "",
		theme_advanced_toolbar_location: "top",
		theme_advanced_toolbar_align: "left",
		// theme_advanced_statusbar_location : "bottom",
		theme_advanced_resizing: true
	});
}
