$(function(){
  // Send ajax request with all forms data for given tabs block.
  function save_tab(tabs){
    var data=""
    tabs.find("form").each(function(){
      data=data+$(this).serialize()
    })
    //alert(data)
    $.ajax({
      url:tabs.attr("data-tabs-url"),
      dataType:"html",
      type:tabs.attr("data-method"),
      data:data,
      success:function(data){
        $("#content").html(data);
        load_tinymce();
      }
    })
  }
  // Submit all forms through Ajax when Save All button clicked.
  $("button.save-all").live('click',function(){
    //var tab=$(this).parents("div[data-tabs-url]")
    var tab = $("#content").children("div[data-tabs-url]")
    save_tab(tab)
  })
  // All tabs are closable when clicked on tab title.
  $(".tab .tab-title").live('click',function(){
    var tab_title=$(this)
    var closed=tab_title.data("closed") || (tab_title.attr("data-closed")=="false" ? false : true)
      if(closed){
        tab_title.parents(".tab").find(".tab-content").show("fast")
      }else{
        tab_title.parents(".tab").find(".tab-content").hide("fast")
      }
      tab_title.data("closed",!closed)
    })
    // Flash is hidden when clicked on
  $("#flash").live("click", function(){
    $(this).slideUp("fast");
  })
})