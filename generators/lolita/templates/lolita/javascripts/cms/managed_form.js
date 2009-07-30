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
            toggleTinyMCEFromFields(FormInformation.fields,false)
            FormInformation.form=null
            FormInformation.fields=null
        }
    }catch(err){
    //FormCleaner can bet undefined
    }
}

function submitForm(form_id,on_success){
    ITH.Cms.wait.show()
    clearForm(true)
    $.ajax({
        url:$(form_id).attr("action"),
        data:$(form_id).serialize(),
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
function toggleTinyMCEFromFields(is_on){
    var tab_fields=FormInformation.fields
    for(var i in tab_fields){
        var object=tab_fields[i][0]
        var field=tab_fields[i][1]
        if (field.type=='textarea'  && !field.simple){
            toggleTinyMCE(is_on,object+"_"+field.field)
        }
    }
}

function toggleTinyMCE(is_on,id){
    try{
        if(is_on && tinyMCE.getInstanceById(id) == null){
            tinyMCE.execCommand('mceAddControl', false,id );
        }else{
            if(tinyMCE.getInstanceById(id) != null){
                tinyMCE.execCommand('mceRemoveControl', false,id );
            }
        }
    }catch(err){
        window.location.reload() //If error acured when trying to add tinyMCE editors,
    }                        //User do not know what went wrong
    
    
}