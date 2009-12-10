function ajax_paginator(url,container,params){
    $.ajax({
        url:url,
        type:"GET",
        dataType:"html",
        data:params,
        success:function(response){
            $(container).html(response)
        }
    })
}
function loadjscssfile(filename, filetype){
    if (filetype=="js"){ //if filename is a external JavaScript file
        var fileref=document.createElement('script')
        fileref.setAttribute("type","text/javascript")
        fileref.setAttribute("src", filename)
    }
    else if (filetype=="css"){ //if filename is an external CSS file
        fileref=document.createElement("link")
        fileref.setAttribute("rel", "stylesheet")
        fileref.setAttribute("type", "text/css")
        fileref.setAttribute("href", filename)
    }
    if (typeof fileref!="undefined")
        document.getElementsByTagName("head")[0].appendChild(fileref)
}
function elementById(id){
    if (document.getElementById)
        return (document.getElementById(id));
    if (document.all)
        return document.all[id];
    if (document.layers)
        return document.layers[id];
    return false;
}
Array.prototype.in_array = function(p_val) {
	for(var i = 0, l = this.length; i < l; i++) {
		if(this[i] == p_val) {
			return true;
		}
	}
	return false;
}
Array.prototype.remove=function(s){
var i = this.indexOf(s);
if(this.indexOf(s) != -1)this.splice(i, 1);
}