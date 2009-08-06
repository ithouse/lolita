/*
 *         developed by Matteo Bicocchi on JQuery
 *         © 2002-2009 Open Lab srl, Matteo Bicocchi
 *			    www.open-lab.com - info@open-lab.com
 *       	version 1.0
 *       	tested on: 	Explorer and FireFox for PC
 *                  		FireFox and Safari for Mac Os X
 *                  		FireFox for Linux
 *         GPL (GPL-LICENSE.txt) licenses.
 *
 * CONTAINERS BUILD WITH BLOCK ELEMENTS
 */


var msie6=$.browser.msie && $.browser.version=="6.0";
var Opera=$.browser.opera;
var zi=100;
jQuery.fn.buildContainers = function (options){
	return this.each (function ()
	{
		if ($(this).is("[inited=true]")) return;

		this.options = {
			containment:"document",
			elementsPath:"elements/"
		}
		$.extend (this.options, options);
		var container=$(this);
		container.attr("inited","true");
		container.addClass(container.attr("skin"));
		if (!container.attr("minimized")) container.attr("minimized","false");
		container.find(".n:first").attr("unselectable","on");
		if (!container.find(".n:first").html()) container.find(".n:first").html("&nbsp;")
		var icon=container.attr("icon")?container.attr("icon"):"";
		var buttons=container.attr("buttons")?container.attr("buttons"):"";
		container.setIcon(icon, this.options.elementsPath);
		container.setButtons(buttons,this.options.elementsPath);
		if (container.attr("width")){
			container.css({width:container.attr("width")+"px"});
		}

		if (container.attr("height")){
			container.find(".c:first , .content:first").css("height",container.attr("height")-container.find(".n:first").outerHeight()-(container.find(".s:first").outerHeight()));
		}

		if (container.hasClass("draggable")){
			container.css({position:"absolute", margin:0});
			container.find(".n:first").css({cursor:"move"});
			container.css({zIndex:zi++});

			container.draggable({handle:".n:first",cancel:".c",delay:0, containment:this.options.containment});
			container.mousedown(function(){
				$(this).css({zIndex:zi++});
			});
		}
		if (container.hasClass("resizable")){
			container.containerResize();
		}
		if (container.attr("minimized")=="true"){
			container.attr("minimized","false");
			container.minimize(this.options.elementsPath);
		}
		if (container.attr("iconized")=="true"){
			container.attr("iconized","false");
			container.iconize();
		}

	});
}
jQuery.fn.containerResize = function (){
	var isDraggable=$(this).hasClass("draggable");
	$(this).resizable({
		handles:isDraggable ? "":"s",
		minWidth: 150,
		minHeight: 150,
		iframeFix:true,
		helper: "proxy",
		stop:function(e,o){
			var resCont= msie6 || Opera ?o.helper:$(this);
			var elHeight= resCont.outerHeight()-$(this).find(".n:first").outerHeight()-($(this).find(".s:first").outerHeight());
			$(this).find(".c:first , .content:first").css({height: elHeight});

			if (!isDraggable){

				var elWidth=$(this).attr("width") && $(this).attr("width")>0 ?$(this).attr("width"):"100%";
				$(this).css({width: elWidth});
			}
		}
	});
}
jQuery.fn.setIcon = function (icon,path){
	if (icon !="" ){
		$(this).find(".ne:first").prepend("<img class='icon' src='"+path+"icons/"+icon+"' style='position:absolute'>");
		$(this).find(".n:first").css({paddingLeft:15});
	}else{
		$(this).find(".n:first").css({paddingLeft:0});
	}
}
jQuery.fn.setButtons = function (buttons,path){
	var container=$(this);
	if (buttons !=""){
		var btn=buttons.split(",");
		$(this).find(".ne:first").append("<div class='buttonBar'></div>");
		for (var i in btn){
			if (btn[i]=="c"){
				$(this).find(".buttonBar:first").append("<img src='"+path+$(this).attr('skin')+"/close.png' class='close'>");
				$(this).find(".close:first").bind("click",function(){container.fadeOut(200)});
			}
			if (btn[i]=="m"){
				$(this).find(".buttonBar:first").append("<img src='"+path+$(this).attr('skin')+"/min.png' class='minimizeContainer'>");
				$(this).find(".minimizeContainer:first").bind("click",function(){container.minimize(path)});
				$(this).find(".n:first").bind("dblclick",function(){container.minimize(path)});
			}
			if (btn[i]=="p"){
				$(this).find(".buttonBar:first").append("<img src='"+path+$(this).attr('skin')+"/print.png' class='printContainer'>");
				$(this).find(".printContainer:first").bind("click",function(){});
			}
			if (btn[i]=="i"){
				$(this).find(".buttonBar:first").append("<img src='"+path+$(this).attr('skin')+"/iconize.png' class='iconizeContainer'>");
				$(this).find(".iconizeContainer:first").bind("click",function(){container.iconize()});
			}
		}
		var fadeOnClose=$.browser.mozilla || $.browser.safari;
		$(this).find(".buttonBar:first img").css({opacity:.5, cursor:"pointer"}).mouseover(function(){if (fadeOnClose)$(this).fadeTo(200,1)}).mouseout(function(){if (fadeOnClose)$(this).fadeTo(200,.5)});
	}
}
jQuery.fn.minimize = function (path){
	this.each (function ()
	{
		var container=$(this);
		if ($(this).attr("minimized")=="false"){
			this.w = container.outerWidth();
			this.h = container.outerHeight();
			container.find(".icon:first").hide();
			container.find(".o:first").slideUp(100,function(){});
			container.animate({height:container.find(".n:first").outerHeight()+container.find(".s:first").outerHeight()},100,function(){container.find(".icon:first").show()});
			container.attr("minimized","true");
			container.find(".minimizeContainer:first").attr("src",path+$(this).attr('skin')+"/max.png");
			container.resizable("destroy");
		}else{
			container.find(".o:first").slideDown(100,function(){});
			if (container.hasClass("resizable")) container.containerResize();
			container.attr("minimized","false");
			container.find(".icon:first").hide();
			container.animate({height:this.h},100,function(){container.find(".icon:first").show()});
			container.find(".minimizeContainer:first").attr("src",path+$(this).attr('skin')+"/min.png");

		}
	})
}
jQuery.fn.iconize = function (){
	return this.each (function ()
	{
		var container=$(this);
		container.attr("w",container.attr("width") && container.attr("width")>0 ? (!container.hasClass("resizable")? container.attr("width"):container.width()):"100%");
		container.attr("h",container.height());
		container.attr("t",container.css("top"));
		container.attr("l",container.css("left"));
		container.resizable("destroy");
		if (!$.browser.msie) {
			container.find(".no:first").fadeOut("fast");
			container.animate({ height:"32px", width:"32px",left:0},200);
		}else{
			container.find(".no:first").hide();
			container.css({ height:"32px", width:"32px",left:0});
		}
		container.append("<img src='elements/icons/"+(container.attr("icon")?container.attr("icon"):"restore.png")+"' class='restoreContainer' width='32'>");
		container.find(".restoreContainer:first").bind("click",function(){
			if (!$.browser.msie) {
				container.find(".no:first").fadeIn("fast");
				container.animate({height:container.attr("h"), width:container.attr("w"),left:container.attr("l")},200);
				container.find(".c:first , .content:first").css("height",container.attr("h")-container.find(".n:first").outerHeight()-(container.find(".s:first").outerHeight()));
			} else {
				container.find(".no:first").show();
				container.css({ width:container.attr("w"),left:container.attr("l")});
				container.find(".c:first , .content:first").css("height",container.attr("h")-container.find(".n:first").outerHeight()-(container.find(".s:first").outerHeight()));
			}
			container.find(".restoreContainer:first").remove();
			if (container.hasClass("resizable")) container.containerResize();
		});
	});
}