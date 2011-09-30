$(function(){
  // Send ajax request with all forms data for given tabs block.
  function save_tab(tabs){
    var data=""
    tabs.find("form").each(function(){
      data=data+"&"+$(this).serialize()
    })
    //alert(data)
    $.ajax({
      url:tabs.attr("data-tabs-url"),
      dataType:"html",
      type:tabs.attr("data-method"),
      data:data,
      success:function(data){
        $("#content").html(data);
      },
      error:function(xhr, textStatus, errorThrown){
        f = $("#flash");
        f.html("<span style='color:red'>An Error occured, please contact support personel</span>");
        f.slideDown("fast")
      }
    })
  }
  function save_all(){
    var tab = $("#content").children("div[data-tabs-url]")
    save_tab(tab)
  }
  // Submit all forms through Ajax when Save All button clicked.
  $("button.save-all").live('click',function(){
    //var tab=$(this).parents("div[data-tabs-url]")
    save_all()
  })
  // All tabs are closable when clicked on tab title.
  $(".tab .tab-title.grey").live('click',function(){
		$(this).parent().toggleClass("minimized").trigger("tab.toggle")
	})
  // Integer field validator
  $(".integer").live("keydown",function(event){
    // Allow only backspace and delete
    if ( event.keyCode == 46 || event.keyCode == 8 ) {
      // let it happen, don't do anything
    }
    else {
      // Ensure that it is a number and stop the keypress
      if (event.keyCode < 48 || event.keyCode > 57 ) {
        event.preventDefault(); 
      }   
    }
  })

  $("select[data-polymorphic-url]").live("change",function(){
    var url = $(this).attr("data-polymorphic-url")
    var select = $(this)[0]
    var jselect = $(this)
    var id = jselect.attr("id").replace(/_type$/,"_id")
    jselect.find('option').each(function(i){
      var option = $(this);
      if(i==select.selectedIndex){
        var val = option.val()
        if(val.length > 1){
          url = url.replace(/\/klass\//,"/"+val+"/")
          var klass = option.val()
          $.ajax({
            url: url,
            type: "get",
            success:function(html){
              $("#"+id).html(html)
            }
          })
        }else{
          $("#"+id).html("")
        }
        
      }
    })
  })

})
