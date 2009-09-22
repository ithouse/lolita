SimpleFilter=function(){
    return{
        filter:function(value,url){
            new SimpleRequest(this,{
                url:url,
                data:{
                    ferret_filter:value,
                    authenticity_token:AUTH_TOKEN
                },
                method:"post",
                loading:true,
                container:"#content"
            })
        }
    }
}()
AdvancedFilter=function(){
    return{
        hide:function(){
            $("#advanced_filter_dialog").hide(300)
        },
        show:function(action){
            AdvancedFilter.filter_action=action
            $("#advanced_filter_dialog").show(300)
        },
        change:function(filter_id,url){
            if(filter_id>0)
                new SimpleRequest(this,{
                    url:url,
                    data:"advanced_filter="+filter_id,
                    loading:true,
                    container:"#content"
                })
        },
        clear:function(url){
            new SimpleRequest(this,{
                url:url,
                loading: true,
                container:"#content"
            })
        },
        save:function(input,form,url){
            new SimpleRequest(this,{
                url:url,
                method:"post",
                loading:true,
                data:($(form).serialize())+"&advanced_filter[name]="+$(input).val()+"&filter_action="+AdvancedFilter.filter_action,
                container:"#content"
            })
            var select=elementById('saved_filters')
            if(select.selectedIndex>0){
                 $(input).val(select.options[select.selectedIndex].innerHTML);
            }else{
                $(input).val()
            }

            AdvancedFilter.hide()
        },
        send:function(form_id,url){
            new SimpleRequest(this,{
                url:url,
                data:$(form_id).serialize(),
                loading:true,
                success:function(html){
                    var flex_app=getFlexApp('aquamet_readout');
                    if(flex_app)flex_app.refreshList()
                    $('#form_list').html(html)
                }
            })
        },
        add:function(select,index){
            select.options[index].disabled=true;
            try{
                $("#tr_"+select.options[index].value).toggle();
                $("#is_visible_"+select.options[index].value).val(true);
                $("#cb_"+select.options[index].value).attr("checked","checked")
            }catch(e){}
        },
        toggleSelect:function(obj,id){
            $(id).attr("multiple",!$(id).attr("multiple"))
            if($(id).attr("multiple")){
                $(id).css({
                    "height":"100px"
                })
            }else{
                $(id).css({
                    "height":""
                })
            }
            toggle_images(obj,["expand.png","collapse.png"]);
        }
    }
}()
$(function(){
    AdvancedFilter.dialog=$("#advanced_filter_dialog_container").buildContainers({
        containment:"document",
        elementsPath:"/images/jquery/elements/"
    });
});
// This function returns the appropriate reference,
// depending on the browser.
function getFlexApp(appName) {
    if (navigator.appName.indexOf ("Microsoft") !=-1) {
        return window[appName];
    } else {
        return document[appName];
    }
}
    