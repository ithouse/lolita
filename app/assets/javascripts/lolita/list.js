$(function(){
  $("td.with-nested-list a, tr.with-nested-list").live("click",function(event){
    event.preventDefault()
    var was_active = $(this).data("active")
    $("td.with-nested-list a, tr.with-nested-list").data("active",false)
    $(this).data("active",true)

    if($(this).prop("tagName") == "A"){
      var $tr = $(this).parents("tr").eq(0)
      var url = $(this).parent().data("nested-list-url")
    }else{
      $tr = $(this)
      url = $(this).data("nested-list-url")
    }
    if(was_active && $tr.next().hasClass("nested-list")){
      $tr.next().remove()
      $(this).data("active",false)
    }else{
      $.get(url,function(data){
        if($tr.next().hasClass("nested-list")){
          $tr.next().replaceWith(data)
        }else{
          $tr.after(data) 
        }
      })
    }
  })
})