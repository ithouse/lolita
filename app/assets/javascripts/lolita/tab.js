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
  $(".tab.minimized .tab-title").live('click',function(){
		$(this).parent().toggleClass("minimized", 200)
	})
})
