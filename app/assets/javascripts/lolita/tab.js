//= require jquery
//= require jquery-ui
$(function(){
  // Submit all forms through Ajax when Save All button clicked.
  $(document).on('click',"button.save-all",function(){
    $form = $(".tabs form.associated")
    $form.append("<input type='hidden' name='button_pressed' value='"+$(this).data("type")+"' />")
    $form.submit()
  })

  $(document).on("click",".tabs .tab-title h2",function(){
    $(this).parents(".tab-title").find("h2").removeClass("active light").addClass("semi-dark");
    $(this).removeClass("semi-dark").addClass("active light");
    $(".tabs .tab.active").removeClass("active")
    $("#"+$(this).data("tab")).addClass("active")
    resize_all_tinymce_editors()
  })
  // Integer field validator
  $(".integer").numeric()

  $(document).on("change","select[data-polymorphic-url]",function(){
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

  $(document).on("keyup.autocomplete","input[data-autocomplete-url]",function(){
    var $input = $(this)
    $(this).autocomplete({
      source: function(request, response){
        var term_arr = request.term.toString().split(",")
        var term = term_arr[term_arr.length - 1]
        term = term ? $.trim(term) : ""
        $input.data("term",term)
        $.getJSON(this.element.data("autocomplete-url"), {
          term: term
        }, response)
      },
      focus: function(even,ui){
        if($(this).data("cached")=="yes"){
          var term = new RegExp($(this).data("term") + "$")
          var start_val = $(this).val().toString().replace(term,"")
          $(this).val(start_val+ui.item.value)
          return false
        }else{
          if($(this).data("macro") == "one"){
            return true
          }else{
            return false
          }
        }
      },
      select: function(event, ui){
        if($(this).data("macro") == "one"){
          var $id_holder = $(this).parents(".autocomplete-container").eq(0).find("input[type=hidden]").eq(0);
          if($id_holder){
            $id_holder.val(ui.item.id);
          }
        } else {
          var li = $("<li></li>").appendTo($(this).parents(".autocomplete-container").eq(0).find("ul"));
          li.text(ui.item.value);
          $("<a href=''></a>").text(ui.item.delete_link).appendTo(li);
          $("<input type='hidden'>").attr("name", ui.item.name).val(ui.item.id).appendTo(li);
          if($(this).data("cached")=="no"){
            this.value = "";
          }
          return false;
        }
      }
    });
  });

	$(document).on("click",".autocomplete-container ul li a",function(){
		$(this).closest("li").remove();
		return false;
	})

})
