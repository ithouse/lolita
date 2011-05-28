$(function(){
  $.ajaxSetup({
    headers:{
      "X-CSRF-Token": $("meta[name='csrf-token']").attr("content")
    }
  })
  $("#flash").slideUp("fast");
  $("#flash").live("click", function(){
    $(this).slideUp("fast");
  })

  $("#flash").ajaxComplete(function(e,request){
    var notice=request.getResponseHeader("Lolita-Notice");
    var error=request.getResponseHeader("Lolita-Error");
    var alert_msg=request.getResponseHeader("Lolita-Alert");
    if(notice){
      show_flash("<span style='color:green'>"+notice+"</span>");
    }else{
      if(error){
        show_flash("<span style='color:red'>"+error+"</span>");
      }else{
        if(alert_msg){
          show_flash("<span style='color:yellow'>"+alert_msg+"</span>");
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
