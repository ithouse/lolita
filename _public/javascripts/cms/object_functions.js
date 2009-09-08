String.prototype.trim = function() {
    return this.replace(/^\s+|\s+$/g,"");
}
ITH.Editor={}

ITH.Editor.TextareaCounter=function(textarea){
    var that = this
    $(document).ready(function(e){
        $(textarea+"_statusbar").css({
            "width": $(textarea).width()+"px",
            "height": "20px",
            "clear": "left",
            "float": "left",
            "border-left": "1px solid #E7E7E7",
            "border-right": "1px solid #E7E7E7",
            "border-bottom": "1px solid #E7E7E7",
            "padding": "0 2px 0 2px "
        })
        that.replaceText(textarea)
        $(textarea).keyup(function(e){
            that.replaceText(textarea)
        })
    })
}
ITH.Editor.TextareaCounter.prototype={
    replaceText:function(textarea){
        var $el=$(textarea)
        var max=parseInt($el.attr("maxlength"))
        var current=$el.val().length+($el.val().split(/\n/).length-1)
        var val=(max-current)
        if(val<0){
            val="<span style='color:red'>"+ITH.Translations.too_much+"</span>"
        }else{
            if($(textarea+"_counter > span").length){
                $(textarea+"_counter > span").remove()
                $(textarea+"_counter").text( $(textarea+"_counter").text()+"0")
            }
        }
        var text=$(textarea+"_counter").html()
        var new_value=text.replace(/\d+$/,val)
        $(textarea+"_counter").html(new_value);
    }
}
ITH.Editor.AutoComplete=function(text_field_id,result_container_id,url){
    var oDS = new YAHOO.util.XHRDataSource(url);
    oDS.responseType = YAHOO.util.XHRDataSource.TYPE_TEXT;
    oDS.connXhrMode="cancelStaleRequests";
    oDS.maxCacheEntries = 0;
    oDS.responseSchema = {
        recordDelim: "\t",
        fieldDelim: "\n"
    };
    var widget=new YAHOO.widget.AutoComplete(text_field_id, result_container_id, oDS,{
        animSpeed:0.1
        
    });
//    YAHOO.util.Event.addListener(widget,"itemSelectEvent",this.itemSelect,this,true)
//    YAHOO.util.Event.addListener(widget,"textboxKeyEvent",this.textChange,this,true)
    widget.itemSelectEvent.subscribe(this.itemSelect);
    widget.textboxKeyEvent.subscribe(this.textChange);
//widget.dataReturnEvent.subscribe(this.dataReturn)
}
ITH.Editor.AutoComplete.prototype={
    itemSelect:function(sType,args){
        var autocomplete=args[0];
        var parts=autocomplete._sInitInputValue.split(",")
        if(autocomplete._sInitInputValue[autocomplete._sInitInputValue.length-1]==","){
            var len=parts.length
        }else{
            len=parts.length-1
        }
        var value=""
        for(var i=0;i<len;i++){
            if(parts[i].length>0) value+=parts[i]+","
        }
        value+=args[2][0]
        autocomplete._elTextbox.value=value
        autocomplete._elTextbox.defaultValue=value
        return false
    },
    textChange:function(sType,args){
        var autocomplete=args[0]
        autocomplete._sInitInputValue=autocomplete._elTextbox.value
        return false
    }
}
// new ITH.ToggableElement(this,"target_1",{images:["arrow_n.gif",[arrow]]}
ITH.ToggableElement=function(object,target,config,request_config){
    this.configuration=config || {}
    this.object=object
    this.target=target
    this.load_target=null
    this.request_config=request_config || {}
    this.state=this.configuration.state || false
    
    if(YAHOO.util.Event.DOMReady){
        this.get_objects()
    }else{
        YAHOO.util.Event.addListener(window, "load", this.get_objects, this, true)
    }
    YAHOO.util.Event.addListener(object, "click", this.toggle, this, true)
}
ITH.ToggableElement.prototype={
    toggle:function(e){
        if(typeof(this.object)=="string" || typeof(this.target)=="string") this.get_objects()
        if(this.configuration.images) toggle_images(this.object,this.configuration.images)
        this.switch_target()
        if(this.opened() && this.request_config.url){
            this.request()
        }
    },
    request:function(){
        if(this.configuration.small_loading)add_very_small_loading(this.load_target)
        simple_yui_request(this.object,this.request_config)
        return false;
    },
    get_objects:function(e){
        if(typeof(this.object)=="string") this.object=elementById(this.object)
        if(typeof(this.target)=="string") this.target=elementById(this.target)
        this.load_target=elementById(this.request_config.container)
        this.target.toggle=this
        this.target.style.display=!this.state ? "none" : "block"
    //this.switch_target(true)
    },
    switch_target:function(keep_state){
        this.target.style.display=this.state ? "none" : "block"
        if(!keep_state)this.state=!this.state
        return false;
    },
    opened:function(){
        return this.state
    }
}
ITH.Element=function(){
    return{
        add_config:function(element,options){
            for(var i in options){
                element[i]=options[i]
            }
            return element
        },
        create:function(type,options){
            var element=document.createElement(type)
            return ITH.Element.add_config(element,options)
        },
        loading:function(type){
            var types={
                "small":"/images/cms/small-loading.gif",
                "large":"/images/cms/loading.gif"
            }
            var element=document.createElement("img")
            element.src=types[type]
            return element
        },
        optionByValue:function(options,value){
            var option=null
            for(var i=0;i<options.length;i++){
                if(options[i].value==value){
                    option=options[i]
                    break;
                }
            }
            return option
        }
    }
}()
/* 
 * Artūrs Meisters ITHGroup
 * 11.10.2008
 */
/*
 *ITH.Media ir statiska klase, kas glabā un apstrādā informāciju par mēdiju
 *logu, kas ir pievienots tinyMCE teksta redaktoram, iekš ITH CMS sistēmas.
 *
 *Objekti nav jāveido, bet mainoties vecāka elementam, ir jāizsauc funkcija
 *ITH.Media.init(parent:String,parent_id:Integer,temp:Boolean)
 *  parent: objekta nosaukums ar kuru pašlaik notiek darbība, piem., "admin/user"
 *  parent_id: konkrētā objekta id vai arī pagaidu id
 *  temp: vai objekts reāli eksistē
 *
 *Publiski maināmās vērtības
 *  loadingImage - attēls, kas redzams kā pārlādējot sadaļas
 *  container - pamata kontaineri, kuri sadala dialogu
 *  current_media - tekošā mēdija sadaļa, pēc noklusējuma "images"
 *    Pieejamie mēdiji:
 *      - images
 *      - files
 */
ITH.Media=function(){
    var params={}
    
    var loadingImage="/lolita/images/cms/loading.gif"
    var current_media="images"
    var current_element=-1
    var container={
        main:"media_gallery_container",
        header:"ith_media_dialog_header",
        body:"ith_media_dialog_body",
        attributes:'ith_media_attributes'
    }
    //var Dialog=null;
    return{
        /*
         *Inicializācijas funkcija, lai inicializētu objektu ar kuru darobjas
         */
        init:function(parent,parent_id,temp){
            params.parent=parent;
            params.parent_id=parent_id
            params.temp=temp
            this.render()
        },
        /*
         *ITH.Media.render
         * Funkcija reāli izveido dialogu, ir jāizsauc, tad, kad ir ielādēts DOM
         * koks, lai varētu atrast nepieciešamo objektu
         */
        render:function(){
            this.init_dialog()
        },
        /*
         * ITH.Media.init_dialog
         * Funkcija izveido dialoga objektu iekš ITH.Media.Dialog
         * tiek izsaukta no ITH.Media.render, taču var arī izsaukt manuāli
         */
        init_dialog:function(){
            ITH.Media.Dialog= new YAHOO.widget.Dialog("media_gallery",  
            {
                width : "570px",
                zindex:50000,
                postmethod:"manual",
                fixedcenter:true,
                visible : false,  
                effect:[{
                    effect:YAHOO.widget.ContainerEffect.FADE,
                    duration:0.5
                }]
            } ); 
            ITH.Media.Dialog.render();
        },
        /*
         * ITH.Media.show_dialog
         * Funkcija parāda dialogu un pārslēdzas uz tekošā mēdija sadaļu
         */
        show_dialog:function(){
            ITH.Media.change_to(current_media,false,container.main)
            ITH.Media.Dialog.show()
        },
        /*
         * ITH.Media.update_element(element:DOMObject, object:JSON)
         * Funkcija elementam 'element' atjauno atribūtus atkarībā no pašreizējā
         * mēdija.
         * Parametri.
         *  element: DOM elements, parasti attēls vai saite uz failu
         *  object: no Rails saņemtais Hash, kas pārveidots uz JSON masīvu
         */
        update_element:function(element,object){
            element.title=object.title
            if(current_media=="images"){
                element.alt=object.alt
            }else if(current_media=="files"){
                $(element).html(object.caption)
            }
        },
        /*
         * ITH.Media.show_attributes_info(id:Integer,content:String)
         * Parāda un izmaina saturu informatīvajam elementam.
         * Parametri.
         *  id: Objekta id, kam ir izveidots konteiners
         *  content: Teksts, kas tiek ierakstīts, nedrīkst būt html tags, jo tādējādi
         *           tiek kropļots stils
         */
        show_attributes_info:function(id,content){
            $('#ith_media_status_container_'+id).css({
                "display":"block"
            })
            $('#ith_media_status_'+id).html(content)
        },
        /*
         * ITH.Media.show_loading(container:String)
         * Funcija parāda lādēšanas simbolu saņemtajā konteinerā
         * Parametri.
         *  container: Strings, kas ir elementa id 
         */
        show_loading:function(current_container){
            $("#"+current_container).html('<img alt="'+ITH.Translations.wait_dialog_header+'" class="ith-media-loading" src="'+loadingImage+'"/>');
        },
        /*
         * ITH.Media.save_attributes(form:Form, id:Integer)
         * Parametri.
         *  form: Formas elements, kurā atrodas visa vajadzīgā informācija
         *  id: Reālā objekta id, pēc kura var atrast tam piesaistītos DOM objektus
         *  
         * Funkcija saņem formas objektu un id, veido POST pieprasījumu uz mēdiju
         * kontrolieri, lai saglabātu saņemās vērtības no formas.
         * Kļūdas gadījumā parāda kļūdas paziņojumu,
         * veiksmīgā gadījumā parāda atbilstošu paziņojumu un atjauno elementu ar 
         * atbilstošo id, izmainot tā atribūtus DOM objektam
         */
        save_attributes:function(form,id){
            this.show_attributes_info(id,ITH.Translations.saving)
            var requestHandler={
                success: function(request){
                    ITH.Media.show_attributes_info(request.argument.id,ITH.Translations.changes_saved+"!")
                    var object=eval(request.responseText)
                    object=object[0]
                    var element=$('#ith_media_list_element_'+request.argument.id);
                    ITH.Media.update_element(element,object)
                },
                failure:function(request){
                    ITH.Media.show_attributes_info(request.argument.id,ITH.Translations.media_error)
                },
                argument:{
                    id:id
                }
            };
            YAHOO.util.Connect.asyncRequest('POST', "/media/save_attributes/"+id, requestHandler,Form.serialize(form)+"&media="+current_media);
            return false;
        },
        /*
         * ITH.Media.open_attributes(id:Integer)
         * Parametri.
         *  id: Objekta id, pēc kura var atrast tam piesaistītos DOM objektus
         * Funkcija veic pieprasījumu uz mēdiju kontrolieri, veiksmīgā gadījumā kā 
         * atbilde tiek saņemta ievades forma atbilstošajam elementam.
         * Kļūdas gadījumā nekas netiek parādīts!
         */
        open_attributes:function(id){
            current_element=id
            this.show_loading(container.attributes)
            var requestHandler={
                success: function(request){
                    $('#ith_media_attributes').html(request.responseText)
                },
                failure:function(request){
                    ITH.Media.close_attributes()
                },
                argument:{
                    id:id
                }
            };
            YAHOO.util.Connect.asyncRequest('POST', "/media/open_attributes/"+id, requestHandler,"media="+current_media);
        },
        /*
         * ITH.Media.close_attributes
         * Funkcija iztīra un tādējādi arī aizver atribūtu konteineri
         */
        close_attributes:function(){
            el=$('#ith_media_attributes')
            if(el) el.html("")
        },
        delete_element:function(id){
            if(current_element==id) this.close_attributes()
            this.make_request("/media/destroy/"+id,container.body)
        },
        show_details:function(id){
            this.close_attributes();
            this.make_request("/media/detail/"+id,container.body)
        },
        add_new:function(){
          
        },
        /*
         * ITH.Media.change_to(media:String,current_item:DOMObject)
         * Parametri.
         *  media: kāds no iepsējamajiem mēdijiem(skatīt klases sākumu)
         *  current_item: tekošais elements, kas norāda uz mēdiju, vajadzīgs, lai
         *                nomainītu klasi, tādējādi mainot arī izskatu
         * Ir vienīgā funkcija kas maina tekošo mēdiju un veic pierasījumu, lai to
         * parādītu. Ja ir tekošais elements, tad sameklē visus ar mēdiju norādes 
         * klasi un nomaina klases un noklusēto, tad padotajam nomaina uz tekošo
         */
        change_to:function(media,current_item,current_container){
            current_media=media;
            this.close_attributes();
            this.make_request("/media/all_"+media,current_container)
            if(current_item){
                $(".media-selector").each(function(i){
                    $(this).removeClass("active-media")
                })
                current_item.className="media-selector active-media"
            }
        },
        /*
         * ITH.Media.make_request(url:URLString)
         * Parametri.
         *  url: Strings, kas ir apmierina adreses prasības, piemēram, "admin/user/1"
         * Funkcija veic pieprasījumu uz norādīto adresi.
         * Kā parametri tiek padoti tiek kas glabājas params mainīgajā un kas tika
         * saņemti caur init funkciju. Veiksmīgā gadījumā parāda saņemto, kļūdas
         * gadījumā parāda kļūdas paziņojumu.
         */
        make_request:function(url,current_container){
            current_container=current_container || container.body
            this.show_loading(current_container)
            var requestHandler={
                success: function(request){
                    $("#"+request.argument.container).html(request.responseText);
                },
                failure:function(request){
                    $("#"+request.argument.container).html(ITH.Translations.media_error);
                },
                argument:{
                    caller:this,
                    container:current_container
                }
            };
            p="parent="+params.parent+"&parent_id="+params.parent_id+"&temp="+params.temp+"&media="+current_media
            if(current_container!=container.main){
                for(var i in container){
                    if(container[i]==current_container){
                        p+="&container="+i
                    }
                }
            }
            YAHOO.util.Connect.asyncRequest('POST', url, requestHandler,p);
        }
    }
}()
ITH.ImageFile=function(){
    var loadingImage="/lolita/images/cms/loading.gif"
    var refreshLoadingImage="/lolita/images/icons/arrow_refresh_loading.gif"
    var refreshImage="/lolita/images/icons/arrow_refresh.png"
    return{
        init:function(config){
            if(!ITH.ImageFile.Dialog){
                this.render_dialog()
            }
            this.parameters=config
        },
        show_attributes_dialog:function(config){
            this.configuration=config
            ITH.ImageFile.Dialog.show();
            this.open_attributes()
        },
        show_loading:function(){
            ITH.ImageFile.Dialog.setBody('<img alt="'+ITH.Translations.wait_dialog_header+'" class="ith-media-loading" src="'+loadingImage+'"/>')
        },
        open_comments:function(config){
            this.make_simple_request("/cms/comment/inline_comments",{
                parent_id:config.id,
                parent:"ImageFile"
            },"picture_comments_container")
        },
        open_attributes:function(config){
            if(config) this.configuration=config
            ITH.ImageFile.Dialog.setHeader(ITH.Translations.picture_attributes)
            ITH.ImageFile.Dialog.setFooter("")
            this.show_loading()
            this.dialog_request("/media/image_file/attributes/"+this.configuration.id)
        },
        save_attributes:function(form,id){
            ITH.ImageFile.Dialog.setFooter(ITH.Translations.saving)
            var that=this
            $.ajax({
                type:"post",
                url:"/media/image_file/save_attributes/"+id,
                data:$(form).serialize(),
                dataType:"json",
                success:function(picture){
                    ITH.ImageFile.Dialog.setFooter(ITH.Translations.changes_saved+"!")
                    element=$('#normalpicturesthumb_'+picture.id)
                    element.attr("title",picture.title)
                    element.attr("alt",picture.alt)
                    ITH.ImageFile.Dialog.setBody("")
                    ITH.ImageFile.Dialog.hide();
                },
                error:function(){
                    ITH.ImageFile.Dialog.setFooter(ITH.Translations.media_error)
                }
            })
            
            return false;
        },
        render_dialog:function(){
            ITH.ImageFile.Dialog=new YAHOO.widget.Dialog("pic_title_dialog",{ 
                width : "300px",
                postmethod:"manual",
                zindex:50000,
                fixedcenter : true,
                visible : false, 
                constraintoviewport : true
            });
            ITH.ImageFile.Dialog.render();
        },
        check_state:function(event,obj,id){
            hidden_element=$("#"+obj.id+'_hidden');
            if (hidden_element){
                if(obj.state){
                    obj.state=false;
                    hidden_element.attr("name","thumb[normal]");
                    obj.className="normal-picture-thumb";
                    changeOpacity(obj,1);
                }else{
                    obj.state=true;
                    rec_id=obj.id.split('_')
                    rec_id=rec_id[1]
                    hidden_element.attr("name","thumb["+rec_id+"]");
                    obj.className="deleted-picture-thumb";
                    changeOpacity(obj,0.5)
                }
            }
        },
        refresh_list:function(config){
            //cfg=config ? json_to_params(config) : json_to_params(this.parameters)
            toggle_images(elementById("picture_list_refresh_button"),[refreshImage,refreshLoadingImage])
            simple_yui_request(this,{
                url:"/media/image_file/reload",
                params:config || this.parameters,
                container:'picture_list_container',
                success:'toggle_images(elementById("picture_list_refresh_button"),["'+refreshImage+'","'+refreshLoadingImage+'"])'
            })
        },
        remove_main:function(config){
            cfg=config ? json_to_params(config) : json_to_params(this.parameters)
            this.make_simple_request("/media/image_file/remove_large_picture",cfg,'picture-photos-main')
        },
        dialog_request:function(url){
            var requestHandler={
                success: function(request){
                    $(ITH.ImageFile.Dialog.body).html(request.responseText);
                    ITH.ImageFile.Dialog.center();
                //ITH.ImageFile.Dialog.setBody(request.responseText)
                },
                failure:function(request){
                    ITH.ImageFile.Dialog.setBody("")
                },
                argument:{
                    caller:this
                }
            };
            var req=YAHOO.util.Connect.asyncRequest('POST', url, requestHandler,"");
            return false;
        },
        make_simple_request:function(url,params,container){
            $.ajax({
                url:url,
                type:"post",
                data:params,
                success:function(html){
                    $("#"+container).html(html)
                },
                failure:function(){
                    alert(ITH.Translations.media_error);
                }
            })
            return false;
        //            new Ajax.Request(url,
        //            {
        //                asynchronous:true,
        //                evalScripts:true,
        //                method:'POST',
        //                onComplete:function(request){
        //                    $("#"+container).html(request.responseText)
        //                },
        //                onFailure:function(request){
        //                    alert(ITH.Translations.media_error)
        //                },
        //                parameters:params
        //            }); return false;
        }
    }
}()
ITH.ImageFileVersions=function(){
    var id="#picture_versions_dialog";
    var container="#picture_versions";
    var default_version="cropped";
    var default_width=220;
    var default_height=220
    $(document).ready(function(e){
        $(function(){
            ITH.ImageFileVersions.Dialog=$(id).buildContainers({
                containment:"document",
                elementsPath:"/lolita/images/jquery/elements/"
            });
        });
    });
    return {
        set_versions:function(versions){
            this.versions=versions;
        },
        start_loading:function(){
            $("#picture_version_dialog_content").hide()
            $("#picture_version_loading").show()
        },
        stop_loading:function(){
            $("#picture_version_dialog_content").show()
            $("#picture_version_loading").hide()
        },
        save:function(){
            if(this.coords && this.coords.w && this.coords.h && this.current_version){
                var that=this;
                this.start_loading();
                $.ajax({
                    url:"/media/image_file/recreate",
                    type:"post",
                    dataType:"json",
                    data:{
                        width:this.coords.w,
                        height:this.coords.h,
                        x:this.coords.x,
                        y:this.coords.y,
                        version:this.current_version,
                        id:this.current_id
                    },
                    success:function(json){
                        that.v_info=json.info;
                        that.load_original_picture();
                    },
                    complete:function(){
                        that.stop_loading()
                    }
                })
            }
        },
        load:function(config){
            this.show();
            if(!this.loaded){
                loadjscssfile("/javascripts/jquery/Jcrop/jquery.Jcrop.js","js");
                loadjscssfile("/stylesheets/jquery.Jcrop.css","css")
                loadjscssfile("/stylesheets/admin/image.cropper.css","css")
                this.loaded=true
            }
            this.load_image(config.id,default_version)
        },
        show:function(){
            $(container).show();
        },
        hide:function(){
            $(container).hide();
        },
        load_image:function(id,version){
            this.current_id=id
            this.current_version=version
            this.start_loading();
            var that=this;
            $.ajax({
                url:"/media/image_file/load_image_for_cropping",
                type:"get",
                dataType:"json",
                data:{
                    "id":id,
                    "version":version,
                    "all_versions":true
                },
                success:function(data){
                    that.base_info=data.info;
                    that.diffs=that.set_differenced_dimensions(that.base_info.width,that.base_info.height)
                    that.info=data.info;
                    that.versions_info=data.versions_info
                    that.next_picture=data.next
                    that.prev_picture=data.prev
                    that.add_new_image_url(data.url)
                },
                complete:function(){
                    that.stop_loading();
                }
            });
            this.clear();
        },
        set_differenced_dimensions:function(w,h){
            var h_diff=w>h ? w/h : 1
            var w_diff=h>w ? h/w : 1
            $("div.preview").css({
                "height":(default_height/h_diff)+"px",
                "width":(default_width/w_diff)+"px"
            })
            return {
                width:w_diff,
                height:h_diff
            }
        },
        add_new_image_url:function(url){
            $(".workarea > img").each(function(index){
                $(this).attr("src",url);
            });
            this.load_cropper();
        },
        load_version:function(version){
            if(version!=this.current_version){
                this.v_info=this.versions_info[version];
                this.info=this.versions[version];
                this.diffs=this.set_differenced_dimensions(this.info.width,this.info.height)
                this.current_version=version;
                this.load_original_picture()
                this.load_cropper();
                this.reset_coords();
            }
        },
        load_original_picture:function(){
            $("#current_version_original").css({
                "visibility":"hidden"
            })
            $("#current_version_original").attr("src",this.v_info.url+ '?' + (new Date()).getTime());
            var wd=1;var hd=1;
            if(this.v_info.width>default_width || this.v_info.height>default_height){
                wd=this.v_info.w_diff
                hd=this.v_info.h_diff
            }
//            if(w>cw){ // samzinu lai ietilptu platumā
//                var ratio=w/cw
//                var diff=(h/w)
//                w=w/ratio
//                h=w*diff
//            // alert(w+" w- "+h)
//            }
//            if(h>ch){ // ja samzinot platumu vēl neietilpst augstumā  vai vispār neietilpsts, tad samazinu,
//                ratio=h/ch // lai ietilptu augstumā
//                diff=(w/h)
//                h=h/ratio
//                w=h*diff
//            // alert(w+" h- "+h)
//            }
            var w=this.v_info.width>default_width ? default_width : this.v_info.width
            var h=this.v_info.height>default_height ? default_height : this.v_info.height
            $("#current_version_original").css({
                "height":(h*hd)+"px",
                "width":(w*wd)+"px",
                "visibility":"visible"
            })
        },
        //Vajag lai standartizētu piekļuvi koordinātēm
        reset_coords:function(){
            this.cords=null
        },
        set_coords:function(coords){
            this.coords=coords
        },
        //Nostrādā kad maina reģionu
        show_preview:function(coords){
            var self=ITH.ImageFileVersions
            self.set_coords(coords);
            var rx =(default_width/self.diffs.width) / coords.w;
            var ry =(default_height/self.diffs.height)/coords.h;
            jQuery('#current_version_preview').css({
                width: Math.round(rx * self.base_info.width) + 'px',
                height: Math.round(ry * self.base_info.height) + 'px',
                marginLeft: '-' + Math.round(rx * coords.x) + 'px',
                marginTop: '-' + Math.round(ry * coords.y) + 'px'
            });

        },
        set_menu_current:function(){
            for(var v in this.versions){
                if(this.current_version==v){
                    $("#picture_version_menu_"+v).addClass("current");
                }else{
                    $("#picture_version_menu_"+v).removeClass("current");
                }
            }
        },
        load_cropper:function(){
            this.remove_old();
            this.set_menu_current();
            var that=this;
            $(function(){
                this.cropper=$('#current_version_crop_area').Jcrop({
                    onChange: that.show_preview,
                    onSelect: that.show_preview,
                    aspectRatio: that.info.crop ? that.info.width/that.info.height : 0
                });
            });
        },
        clear:function(){
            this.remove_old();
            $("#current_version_preview").attr("src","")
            $("#current_version_original").attr("src","")
        },
        remove_old:function(){
            var temp=$('#current_version_crop_area')[0]
            delete(temp['Jcrop'])
            $(".workarea > div").remove()
            this.cropper=null;
        }
    }
}();
DropReceivingElement=function(id,group){
    this.element=new YAHOO.util.DDTarget(id,group)
};
DraggableElement = function(id, options) {
    DraggableElement.superclass.constructor.call(this, id, options.group);
    var el = this.getDragEl();
    YAHOO.util.Dom.setStyle(el, "opacity", 0.67); // The proxy is slightly transparent
    this.options=options
    this.goingUp = false;
    this.lastY = 0;
};

ITH.extend(DraggableElement, YAHOO.util.DDProxy, {
    startDrag: function(x, y) {
        eval(this.options.before_drag)
        var dragEl = this.getDragEl();
        var clickEl = this.getEl();
        YAHOO.util.Dom.setStyle(clickEl, "visibility", "hidden");
        dragEl.innerHTML = clickEl.innerHTML;
        YAHOO.util.Dom.setStyle(dragEl, "color", YAHOO.util.Dom.getStyle(clickEl, "color"));
        YAHOO.util.Dom.setStyle(dragEl, "background", "url("+clickEl.src+") no-repeat");
        YAHOO.util.Dom.setStyle(dragEl, "border", "1px solid gray");
    },

    endDrag: function(e) {
        eval(this.options.after_drag)
        var srcEl = this.getEl();
        var proxy = this.getDragEl();
        // Show the proxy element and animate it to the src element's location
        YAHOO.util.Dom.setStyle(proxy, "visibility", "");
        var a = new YAHOO.util.Motion( 
            proxy, {
                points: {
                    to: YAHOO.util.Dom.getXY(srcEl)
                }
            },
            0.2,
            YAHOO.util.Easing.easeOut
            )
        var proxyid = proxy.id;
        var thisid = this.id;
        // Hide the proxy and show the source element when finished with the animation
        a.onComplete.subscribe(function() {
            YAHOO.util.Dom.setStyle(proxyid, "visibility", "hidden");
            YAHOO.util.Dom.setStyle(thisid, "visibility", "");
        });
        a.animate();
        proxy_el=elementById(proxyid)
        proxy_el.innerHTML="";
    },

    onDragDrop:function(e,id){
        var destEl = Dom.get(id);
        var elDOM=this.getEl();
        if(!this.req ){
            ITH.Cms.wait.show(); 
            var requestHandler={
                success: function(r){
                    $("#"+ r.argument.caller.options.update.success).html(r.responseText);
                    r.argument.caller.req=null;
                    ITH.Cms.wait.hide();
                },
                failure:function(r){
                    // $("#"+r.argument.caller.options.update.failure).html(r.responseText);
                    r.argument.caller.req=null;
                    ITH.Cms.wait.hide();
                },
                argument:{
                    caller:this
                }
            };
            this.req=YAHOO.util.Connect.asyncRequest('POST', this.options.url, requestHandler,"is_ajax=true");
        }
    }
});
AutoUploadForm=function(action,form_id,element_id,e,target,config){
    this.form_id=form_id;
    this.target=target || false;
    this.action=action;
    observable_event=e || 'change'
    this.config=config||{}
    temp_input=elementById(element_id);
    YAHOO.util.Event.on(element_id, observable_event, this.doUpload,this,true);
};
AutoUploadForm.prototype= {
    /*
     * Inicialize file auto upload form
     * @method initialize
     * @param {String} action Ruby action to call
     * @param {String} form_id HTML form including input field with type file id
     * @param {String} element_id HTML input field element id
     * @param {String} target_id DOM element to update
     * @param {Boolean} overwrite Either add html or replace
     */

    doUpload:function(e){
        YAHOO.util.Connect.setForm(this.form_id, true);
        var uploadHandler={
            upload: function(request){
                var self=request.argument.caller
                $("#"+self.target).html(request.responseText)
                if(self.config.type=="picture" && request.responseText==""){
                    ITH.ImageFile.remove_main()
                }
            },
            failure:function(request){
                
            },
            argument:{
                caller:this
            }
        };
        upReq=YAHOO.util.Connect.asyncRequest('POST', this.action, uploadHandler);
    }
}

