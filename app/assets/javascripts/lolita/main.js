//= require jquery_ujs
$(function(){
  $.ajaxSetup({
    headers:{
      "X-CSRF-Token": $("meta[name='csrf-token']").attr("content"),
      "lolita_xhr": "true"
    }
  })
  //$("#flash").slideUp("fast");
  $("#flash").live("click", function(){
    $(this).slideUp("fast");
  })

  $("#flash").ajaxComplete(function(e,request){
    show_lolita_messages(request)
  })
})

function show_lolita_messages(request){
  var notice=request.getResponseHeader("Lolita-Notice");
  var error=request.getResponseHeader("Lolita-Error");
  var alert_msg=request.getResponseHeader("Lolita-Alert");
  if(notice){
    show_notice_msg(Base64.decode(notice))
  }else{
    if(error){
      show_error_msg(Base64.decode(error))
    }else{
      if(alert_msg){
        show_alert_msg(Base64.decode(alert_msg))
      }
    }
  }
}


function resize_all_tinymce_editors(){
  $("textarea").each(function(item,index){
    try{
      tinymce_id = $(this).tinymce().editorId
    }catch(err){
      tinymce_id = false
    }
    if(tinymce_id){
      var $textarea = $("#"+tinymce_id)
      var $parent = $textarea.parent()
      var h = $textarea.height();
      $parent.find('.mceEditor').css('width','100%').css('minHeight',h + "px");
      $parent.find('.mceLayout').css('width','100%').css('minHeight',h + "px");
      $parent.find('.mceIframeContainer').css('width','100%').css('minHeight',h + "px");
      $parent.find("iframe").css("width","100%").css("minHeight",h + "px") 
    }
  })
}

function params(object_or_name,new_value){
  var url = window.location.href
  if(typeof(object_or_name) && object_or_name.constructor.toString().match(/Object/)){
    for(var name in object_or_name){
      var value = object_or_name[name]
      url = apply_param_to_url(name,value,url)
    }
  }else{
    url = apply_param_to_url(object_or_name,new_value,url)
  }
  window.location.href = url.replace(/&{2,}/,"&")
}

function apply_param_to_url(name,new_value,url){
  var value = (url.match(RegExp(name+"=([^&]*)(&|$)")) || [])
  if(new_value){
    if(value[0]){
      replace_value = !new_value ? "" : (name + "=" + new_value + value[2])
      url = url.replace(RegExp(name+"=([^&]*)(&|$)"),replace_value)
    }else{
      start_sym = url.match(/\?/) ? "&" : "?"
      url = url + (start_sym+name+"="+new_value)
    }
  }else{
    url =  url.replace(RegExp(name+"=([^&]*)(&|$)"),"")
  }
  return encodeURI(url)
}

function show_notice_msg(msg){
  show_msg("green",msg)
}

function show_error_msg(msg){
  show_msg("red",msg)
}

function show_alert_msg(msg){
  show_msg("#ea7c15",msg)
}

function show_msg(color,msg){
  show_flash("<span style='color:"+color+"'>"+msg+"</span>");
}

function show_flash(html){
  var flash=$("#flash")
  flash.stop(true)
  flash.hide(0)
  flash.html(html)
  flash.slideDown("fast").delay(8000).slideUp("fast",function(){
    $(this).html("")
  })
}
function remove_fields(link) {
  $(link).prev("input[type=hidden]").val(1)
  $(link).parent(".fields").hide();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  var $container = $(link).parent().siblings(".nested-form-fields-container")
  $container.append($(content.replace(regexp, new_id)))
  $container.scrollTop(100000)
}
