ITH.FileUploadDialog=function(container){
    this.container=container
}
ITH.FileUploadDialog.prototype={
  
    createDialog:function(media){
        this.fields={}
        this.media_id=null;
        this.form=null
        this.dialog=false
        this.media=media
        if(!this.upload_url) this.upload_url="/"+media+"/add_picture"
        if(!this.destroy_url) this.destroy_url="/"+media+"/remove_picture"
        if(this.container && !this.dialog){
                
            this.dialog= new YAHOO.widget.Dialog(this.container,
            {
                width : "320px",
                zindex:50000,
                postmethod:"manual",
                visible : false,
                effect:[{
                    effect:YAHOO.widget.ContainerEffect.FADE,
                    duration:0.3
                }]
            });
            this.dialog.render();
            this.createDialogForm()
        }
    },
    createDialogForm:function(){
        if(!this.form){
            this.form=this.createForm();
            this.fields.temp=this.createHiddenField(this.media,"picture_temp")
            this.fields.upload=this.createUploadField()
            this.fields.parent_id=this.createHiddenField(this.media,"id")
            for(var i in this.fields){
                this.form.appendChild(this.fields[i])
            }
            YAHOO.util.Event.on(this.media+"_picture","change", this.doUpload,this,true);
            this.dialog.body.innerHTML=""
            this.dialog.body.appendChild(this.form)
        }
        return this.form
    },
    createForm:function(){
        form=document.createElement("form");
        form.id=this.container+"_form";
        form.enctype="multipart/form-data"
        return form
    },
    createHiddenField:function(object,method,value){
        var h_field=document.createElement("input")
        h_field.id=object+"_"+method;
        h_field.name=object+"["+method+"]"
        h_field.type="hidden"
        if(value) h_field.value=value
        return h_field
    },
    createUploadField:function(){
        var upload_field=document.createElement("input");
        upload_field.id=this.media+"_picture"
        upload_field.name=this.media+"[picture]"
        upload_field.size=30
        upload_field.type="file"
        return upload_field
    },
    doUpload:function(){
        YAHOO.util.Connect.setForm(this.form.id, true);
        var uploadHandler={
            upload: function(request){
                try{
                    ITH.Cms.wait.hide()
                    request.argument.caller.hide()
                }catch(e){}
                //request.responseText+="<script type='text/javascript'>so.write('"+"#single_"+request.argument.media+"_row_"+request.argument.id+"_swf');</script>"
                $("#single_"+request.argument.media+"_row_"+request.argument.id).html(request.responseText)
            },
            failure:function(request){
                ITH.Cms.wait.hide()
            },
            argument:{
                caller:this,
                id:this.fields.parent_id.value,
                media:this.media
            }
        };
        ITH.Cms.wait.show()
        upReq=YAHOO.util.Connect.asyncRequest('POST', this.upload_url, uploadHandler);
    },
    destroy:function(v_id){
        this.media_id=v_id;
        var that=this
        ITH.Cms.wait.show()
        $.ajax({
            url:this.destroy_url,
            type:"POST",
            data:"id="+v_id,
            complete:function(){
                ITH.Cms.wait.hide()
            },
            success:function(data){
                $("#single_"+that.media+"_row_"+that.media_id).html(data)
            }
        })
    },
    open:function(v_id){
        this.fields.parent_id.value=v_id
        this.show()
    },
    show:function(){
        if(this.dialog) {
            this.dialog.show()
            this.dialog.moveTo(screen.availWidth-(250+screen.availWidth/4),screen.availHeight-screen.availHeight/1.5)
        }
    },
       
    hide:function(){
        if(this.dialog) this.dialog.hide()
    }
}
