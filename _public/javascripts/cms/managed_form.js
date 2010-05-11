FormCleaner=null
FormInformation={
    form:null,
    fields:null
}
function addFormCleaner(form,fields){
    clearForm()
    FormInformation.form=form //need set because tinyMCE loading depends on it
    FormInformation.fields=fields

    FormCleaner=setInterval(function(form,fields){
        try{
            if(!$(form).length){
                FormInformation.form=form //need to set because for some reasons it is null
                FormInformation.fields=fields
                clearForm()
            }
        }catch(err){
        //jQuery can be undefined
        }
    },500,form,fields)
}

function clearForm(force){
    try{
        if(force || FormCleaner){
            //alert(FormInformation.fields)
            clearInterval(FormCleaner)
            FormCleaner=null
            unloadTinyMCEfields()
            FormInformation.form=null
            FormInformation.fields=null
        }
    }catch(err){
    //FormCleaner can bet undefined
    }
}

function submitForm(form_id,on_success,only_save){
    ITH.Cms.wait.show()
    clearForm(true)
    var post_data=$(form_id).serialize()
    if(only_save) post_data+="&only_save=true"
    $.ajax({
        url:$(form_id).attr("action"),
        data:post_data,
        type:"post",
        success:function(data){
            eval(on_success)
        },
        failure:function(){
            ITH.Cms.warning.show()
        },
        complete:function(){
            ITH.Cms.wait.hide()
        }
    })
}
function toggleTinyMCEFromFields(is_on,acceptable_objects){
    var tab_fields=FormInformation.fields
    acceptable_objects=acceptable_objects || []
    for(var i in tab_fields){
        var object=tab_fields[i][0]
        var field=tab_fields[i][1]
        var object_is_good=acceptable_objects.length==0 ? true : false
        if(!object_is_good){
            for(var p in acceptable_objects){
                if(acceptable_objects[p]==object){
                    object_is_good=true;break;
                }
            }
        }
        if (object_is_good && field.type=='textarea'  && !field.simple){
            toggleTinyMCE(is_on,object+"_"+field.field)
        }
    }
}

function toggleTinyMCE(is_on,id){
    try{
        if(is_on && tinyMCE.getInstanceById(id) == null){
            tinyMCE.execCommand('mceAddControl', false,id );
        }else{
            if(!is_on && tinyMCE.getInstanceById(id) != null){
                tinyMCE.execCommand('mceRemoveControl', false,id );
            }
        }
    }catch(err){
        window.location.reload() //If error acured when trying to add tinyMCE editors,
    }                        //User do not know what went wrong
}
function unloadTinyMCEfields(acceptable_objects){
    var tab_fields=FormInformation.fields
    acceptable_objects=acceptable_objects || []
    for(var i in tab_fields){
        var object=tab_fields[i][0]
        var field=tab_fields[i][1]
        var object_is_good=acceptable_objects.length==0 ? true : false
        if(!object_is_good){
            for(var p in acceptable_objects){
                if(acceptable_objects[p]==object){
                    object_is_good=true;break;
                }
            }
        }
        if (object_is_good && field.type=='textarea'  && !field.simple){
            tinyMCE.execCommand('mceRemoveControl', false,object+"_"+field.field );
        }
    }
}