$(function(){
  $(".with-nested-list").live("click",function(){
    var url = $(this).data("nested-list-url")
    if($(this).prop("tagName") == "TD"){
      var $tr = $(this).parents("tr").eq(0)
    }else{
      $tr = $(this)
    }
    $.get(url,function(data){
      if($tr.next().hasClass("nested-list")){
        $tr.next().replaceWith(data)
      }else{
        $tr.after(data) 
      }
    })
  })
})