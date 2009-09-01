/*
 * Artūrs Meisters ITHGroup
 * 10.11.2008
 *
 * Simple functions to do simple things
 */
/*
 * <b>Obligāti jānorāda:</b><br/>
 *  <tt>url</tt>: String ('/user/show/1')<br/>
 * <b>Var norādīt</b><br/>
 *  <tt>container</tt>: String ('content')<br/>
 *  <tt>params</tt>: json vai String ({id:1,name:'asdf'} vai "id=1&name=asdf")<br/>
 *  <tt>success</tt>: kods ko izpildīs veiksmīga pieprasījuma gadījumā<br/>
 *  <tt>failure</tt>: kods ko izpildīs neveiksmīga pieprasījuma gadījumā<br/>
 *  <tt>confirm</tt>: (String) jautājums, kuru apstiprinot tiek veidots pieprasījums un izpildīts lietotāja definētais kods<br/>
 *  <tt>before</tt>: kods ko izpildīt pirms sākt pieprasījumu<br/>
 *  <tt>after</tt>: kods ko izpildīt tūlīt pēc pieprasījuma inicializācijas<br/>
 *  <tt>method</tt>: metode, noklusētā POST<br/>
 *  <tt>loading</tt>: Boolean vai parādīt lādēšanas paziņojumu, pēc noklusējuma false<br/>
 *
 *  Lietotāja definētajām funkcijām <code>before</code> un <code>after</code> ir pieejams
 *  konfigurācijas <tt>config</tt> masīvs ar visu padoto konfigurāciju, bet <code>success</code>
 *  un <code>failure</code> ir pieejams arī <tt>request</tt>, ar pieprasījuma informāciju.
 *  Atbildes teksts: <code>request.responseText</code>
 */
function select_all(object){
    var all_checks=document.getElementsByName('list_check[]');
    for(i=0;i<all_checks.length;i++){
        if(object.checked){
            all_checks[i].checked='checked';
        }else{
            all_checks[i].checked='';
        }
    }
}
function SimpleRequest(r_object,r_config){
    var config=r_config
    var object=r_object
    if(!config) config={}
    var stop=false
    if(config.confirm) var question=config(config.confirm)
    if(!config.confirm || question){
        if(config.before) eval(config.before)
        var request={
            url:config.url,
            type:config.method || "post",
            data:construct_params(config.data),
            dataType: config.dataType || 'html'
        }
        if(config.success){
            request.success=config.success
        }
        if(config.error) request.error=config.error
        request.complete=function(xhr,status){
            try{
                if(config.loading) ITH.Cms.wait.hide()
            }catch(err){}
            try{
                if(status!="success"){
                    ITH.Cms.warning.show()
                }else{
                    if(config.container) $(config.container).html(xhr.responseText)
                }
            }catch(err){}
        }
        if(config.loading){
            try{
                ITH.Cms.wait.show()
            }catch(err){}
        }
        if(!stop) $.ajax(request)
        if(config.after) eval(config.after)
    }
}
function construct_params(params){
    if(params && params.constructor===Object){
        params.is_ajax=true
        params=json_to_params(params)
    }else if(!params){
        params={
            is_ajax:true
        }
        params=json_to_params(params)
    }else{
        params+="&is_ajax=true"
    }
    return params
}
function json_to_params(json){
    var str=""
    for(var i in json){
        str=str+i+"="+json[i]+"&"
    }
    return str
}

function simple_yui_request(object,config){
    if(!config) config={}
    var stop=false //var izmantot savās funkcijās lai apturētu izsaukumu
    if(config.confirm) var question=confirm(config.confirm)
    if(!config.confirm || question){
        if(config.before){
            eval(config.before)
        }
        var requestHandler={
            success:function(request){
                var config=request.argument.config
                var object=request.argument.object
                if(config.container)$("#"+config.container).html(request.responseText)
                if(config.success) eval(config.success)
                try{
                    if(config.loading){
                        ITH.Cms.wait.hide()
                    }
                }catch(e){}
            },
            failure:function(request){
                var config=request.argument.config
                if(config.failure) eval(config.failure)
                try{
                    if(config.loading){
                        ITH.Cms.wait.hide()
                    }
                }catch(e){}
                ITH.Cms.warning.show()
            },
            argument:{
                config:config,
                object:object
            }
        };
        if(config.params && config.params.constructor===Object){
            config.params.is_ajax=true
            config.params=json_to_params(config.params)
        }else if(!config.params){
            config.params={
                is_ajax:true
            }
            config.params=json_to_params(config.params)
        }else{
            config.params+="&is_ajax=true"
        }

        try{
            if(config.loading){
                ITH.Cms.wait.show()
            }
        }catch(e){}
        var method=config.method || 'POST'
        if(method.toLowerCase()=="get"){
            config.url=get_url_with_params(config.url,config.params)
        //config.url=get_url_with_params(config.url,"is_ajax=true")
        }
        if(!stop){
            YAHOO.util.Connect.asyncRequest(method, config.url, requestHandler,config.params);
        }
        if(config.after)eval(config.after)
    }
    return false;
}

Ajax={}
Ajax.Request=function(url,c){
    ITH.Cms.wait.show()
    $.ajax({
        url:url,
        type:c.method || "POST",
        data:c.parameters,
        dataType:"html",
        complete:function(data){
            ITH.Cms.wait.hide()
        },
        error:function(){
            ITH.Cms.warning.show()
        },
        success:c.onSuccess || c.onComplete
    })
}
Form=function(){
    return{
        serialize:function(object){
            return $(object).serialize()
        }
    }
}()
function stop(e){
    if (!e) {
        e = window.event;
    }
    e.cancelBubble = true;
    if (e.preventDefault) {
        e.preventDefault();
    }
    if (e.stopPropagation) {
        e.stopPropagation();
    }
    e.returnValue=false;
}
function add_very_small_loading(id,container_tag){
    if(!id.constructor.toString().search(/object/i)){
        var el=elementById(id)
    }else{
        el=id
    }
    if(!container_tag) container_tag="div"
    var container=document.createElement(container_tag)
    container.style.width="100%"
    container.style.textAlign="right"
    var img=document.createElement("img")
    img.src="/images/cms/small-ajax-loader.gif"
    img.alt=""
    container.appendChild(img)
    el.innerHTML=""
    el.appendChild(container)
}
//function main_image_drag_change(id,visible){
//    visible ? $(id).show() : $(id).hide()
//}
//params var būt tikai kā string "name=asdf&utt=aa"
function get_url_with_params(url,params){
    if(params){
        if(url.match(/\?/)){
            url+="&"+params
        }else{
            url+="?"+params
        }
    }
    return url
}

function refreshFileList(params){
    var requestHandler={
        success: function(request){
            $('#file_list_container').html(request.responseText)
        },
        failure:function(request){},
        argument:{}
    };
    YAHOO.util.Connect.asyncRequest('POST', "/file/refresh",requestHandler, json_to_params(params));
}
function before_ajax_request(params){
    try{
        if(ITH.Picture.Dialog){
            ITH.Picture.Dialog.hide()
        }
        ITH.Cms.wait.show();
    }catch(err){}
    params['is_ajax']=true
    return params
}
function after_ajax_request(status){
    try{
        ITH.Cms.wait.hide();
    }catch(err){}
}
function changeAccessPremission(id,access_id,role_id,permission){
    $(id).change(function(e){
        d="role="+role_id+"&access="+access_id+"&permissions["+permission+"]="+$(this).attr("checked")
        $.ajax({
            url:"/admin/access/change_permission",
            data:d,
            type:"post"
        })
    })
}
function addAccessToggle(id,access_id,role,role_id,prefix){
    $(id).change(function(e){
        var actions=['read','write','update','delete'];
        var is_checked=$(this).attr("checked")
        for(var i=0;i<actions.length;i++){
            var temp_id="#"+prefix+access_id+"-"+role_id+actions[i]
            var $obj=$(temp_id);
            if($obj.length){
                $obj.attr("checked",is_checked)
                $obj.attr("disabled",!is_checked)
            }
        }
        $.ajax({
            url:"/admin/access/"+(is_checked ? "add_role" : "remove_role"),
            type:"post",
            data:{
                access:access_id,
                role:role
            }
        })
    })
}

function setDeleteFormParams(){
    var source=document.getElementsByName('list_check[]');
    var dest=elementById('special_remote_delete_form');
    var values=""
    for(var i=0;i<source.length;i++){
        if (source[i].checked){
            values+=source[i].value+","
        }
    }
    dest.value=values
}

function changeOpacity(obj,opacity){
    $(obj).css({
        "filter":"alfa(opacity="+opacity*100+")",
        "opacity":opacity
    })

}
function elementById(id){
    if (document.getElementById)
        return (document.getElementById(id));
    if (document.all)
        return document.all[id];
    if (document.layers)
        return document.layers[id];
    return false;
}
function switch_tabs(object){
    tabs=document.getElementsByName('tab_content');
    tabHeaders=document.getElementsByName('tab_header');
    for(i=0;i<tabHeaders.length;i++){
        tabHeaders[i].className='';
        $('#tab'+parseInt(tabHeaders[i].id.replace(/tab/,''))+'container').css({
            "display":"none"
        })
    };
    object.className='current';
    el= $("#"+object.id+'container').css({
        "display":"block"
    });
}
function switch_simple_tabs(base_class,current_class,body){
    $(base_class).click(function(event){
        var current=this
        var index=0
        $(base_class).each(function(i){
            $(this).removeClass(current_class)
            if(this==current) index=i+1
        })
        $("."+body).each(function(i){
            $(this).hide()
        })
        $("#"+body+"_"+index).show()
        $(this).addClass(current_class)
    })
}
function toggle_images(object,images){
    for(var i=0;i<images.length;i++){
        if(object.src.match(images[i])) break;
    }
    last=i;
    if(i==images.length-1) i=-1
    object.src=object.src.replace(images[last],images[i+1]);
}
function toggle_tree_arrows(object){
    var el=elementById('object_menu_record_dir');
    toggle_images(object,["arrow_blue_s.gif","arrow_blue_e.gif","arrow_blue_s.gif"])
    if(object.src.match('arrow_blue_s.gif')) el.value='s'
    if(this.src.match('arrow_blue_e.gif')) el.value='e';
    if(this.src.match('arrow_blue_n.gif'))el.value='n';
}
function is_toggle_element_opened(id){
    var el=elementById(id)
    if(el){
        try{
            if(el.toggle.state){
                return true;
            }else{
                return false;
            }
        }catch(err){
            return false
        }
    }else return false
}
function change_public_menus(name){
    $(".content_menu_item_editor select, .content_menu_item_editor input").each(function(i){
        $(this).attr("disabled","disabled")
    })
    $("#content_menu_item_editor_"+name+" select, #content_menu_item_editor_"+name+" input").each(function(i){
        $(this).removeAttr("disabled")
    })

}
function loadjscssfile(filename, filetype){
    if (filetype=="js"){ //if filename is a external JavaScript file
        var fileref=document.createElement('script')
        fileref.setAttribute("type","text/javascript")
        fileref.setAttribute("src", filename)
    }
    else if (filetype=="css"){ //if filename is an external CSS file
        fileref=document.createElement("link")
        fileref.setAttribute("rel", "stylesheet")
        fileref.setAttribute("type", "text/css")
        fileref.setAttribute("href", filename)
    }
    if (typeof fileref!="undefined")
        document.getElementsByTagName("head")[0].appendChild(fileref)
}
function add_new_element_to_autocomplete(id,value){
    var $el=$(id)
    if($el.val().length>0){
        $el.val($el.val()+','+value);
    }else{
        $el.val(value)
    }
    $(id).focus()
}

function URLEncode(str){
  return escape(str).replace(/\+/g,'%2B').replace(/%20/g, '+').replace(/\*/g, '%2A').replace(/\//g, '%2F').replace(/@/g, '%40');
}
function observe_languages(tab,url,params){
  var el=elementById("translation_locale");
  el.url=url
  el.tab=tab
  el.params=params
  if(el){
    YAHOO.util.Event.addListener(el,"change",change_language,el,true)
  }
}
function change_language(e){
  var that=this
  ITH.Cms.wait.show()
  new Ajax.Request(this.url,{
    parameters:this.params+"&translation_locale="+this.value,
    onSuccess: function(data){
      $("#tab"+that.tab+"container").html(data);
    },
    onComplete:function(){
      ITH.Cms.wait.hide()
    }
  });
}
