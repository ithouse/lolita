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
    var notice=request.getResponseHeader("Lolita-Notice");
    var error=request.getResponseHeader("Lolita-Error");
    var alert_msg=request.getResponseHeader("Lolita-Alert");
    if(notice){
      show_flash("<span style='color:green'>"+Base64.decode(notice)+"</span>");
    }else{
      if(error){
        show_flash("<span style='color:red'>"+Base64.decode(error)+"</span>");
      }else{
        if(alert_msg){
          show_flash("<span style='color:#ea7c15'>"+Base64.decode(alert_msg)+"</span>");
        }
      }
    }
  })
})

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
  $(content.replace(regexp, new_id)).insertBefore($(link).parent());
}
