$(function(){
  $.ajaxSetup({
    header:{
      "X-CSRF-Token": $("meta[name='csrf-token']").attr("content")
    }
  })
})