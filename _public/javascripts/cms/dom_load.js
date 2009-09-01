/* 
 * Artūrs Meisters ITHGroup
 * Functions that initialize objects, that use DOM
 */
window.onload=function(){
    init_translations()
    init_namespaces()
    init_menu_translations()
}
FlashLoaderPlayers=[]
ITH.Translations={}

function init_menu_translations(retray){
    //    $(window).keydown(function(event){
    //        if(event.keyCode==8){
    //            a=1
    //        }
    //    })
    var rtry=retray || 1;
    if(ITH.MenuTree.namespace!="wiki_page"){
        $.ajax({
            type:"GET",
            url:"/"+ITH.locale+"/admin/menu/init_translations",
            dataType:"json",
            success:function(data){
                ITH.MenuTree.translation=data
                init_menus()
            },
            error:function(msg){
                if(rtry<3) init_menu_translations(rtry+1)
            }
        })
    }
}
function init_translations(retray){
    var rtry=retray || 1
    $.ajax({
        type:"GET",
        url: "/"+ITH.locale+"/admin/translate/init_translations",
        dataType:"json",
        success:function(data){
            ITH.Translations=data
            init_wait_element()
            init_warn_element()
        },
        error:function(msg){
            if(rtry<3) init_translations(rtry+1)
        }
    })
}
function init_menus(retray){
    var rtry=retray || 1
    if(ITH.MenuTree.namespace!="wiki_page"){
        $.ajax({
            type:"GET",
            url:"/"+ITH.locale+"/admin/menu/init_menus",
            dataType:"script",
            success:function(data){
                if(ITH.MenuTree.active.web){
                    ITH.MenuTree.active.web.destroy()
                    ITH.MenuTree.active.web=null
                }
                if(ITH.MenuTree.active.app){
                    ITH.MenuTree.active.app.destroy()
                    ITH.MenuTree.active.app=null
                }
                eval(data)
                if(ITH.MenuTree.active.app)ITH.MenuTree.active.app.render()
                if(ITH.MenuTree.active.web) ITH.MenuTree.active.web.render()
            },
            error:function(data){
                if(rtry<3) init_menus(rtry+1)
            }
        })
    }
}
function init_namespaces(){
    Dom = YAHOO.util.Dom;
    Event = YAHOO.util.Event;
}
function init_wait_element(){
    $(function(){
        ITH.Cms.wait=$("#wait_dialog").buildContainers({
            containment:"document",
            elementsPath:"/images/jquery/elements/"
        });
    });
    $("#wait").click(function(){
        $("#wait").hide()
    })
    ITH.Cms.wait.show=function(){
        $("#wait").fadeIn(450)
    }
    ITH.Cms.wait.hide=function(show_error){
        $("#wait").animate({
            "opacity":0
        },500,function(e){
            $(this).css({
                "display":"none",
                "opacity":""
            });
        })
        if(show_error) ITH.Cms.warning.show()
    }
}

function init_warn_element(){
    $(function(){
        ITH.Cms.warning=$("#warning_dialog").buildContainers({
            containment:"document",
            elementsPath:"/images/jquery/elements/"
        });
    });
    $("#warning_dialog").click(function(event){
        ITH.Cms.warning.hide()
    })
    ITH.Cms.warning.show=function(){
        $("#warning").fadeIn(450)
    }
    ITH.Cms.warning.hide=function(){
        $("#warning").fadeOut(350)
    }
//    if(!ITH.Cms.warning){
//        var handleYes = function() {
//            this.hide();
//        };
//        ITH.Cms.warning=new YAHOO.widget.SimpleDialog("warning1",
//        {
//            width: "300px",
//            fixedcenter: true,
//            visible: false,
//            draggable: false,
//            modal:true,
//            close: true,
//            text: ITH.Translations.error+"!<br/>"+ITH.Translations.error_dialog_text,
//            icon: YAHOO.widget.SimpleDialog.ICON_WARN,
//            constraintoviewport: true,
//            buttons: [ {
//                text:"Labi",
//                handler:handleYes,
//                isDefault:true
//            }]
//        } );
//        ITH.Cms.warning.setHeader(ITH.Translations.error+"!");
//        ITH.Cms.warning.render("warning_dialog")
//    }
}
