Administration=function(){
    return{
        change_access_permissions:function(obj,url,permission){
            var params="permissions["+permission+"]="+obj.checked
            $.ajax({
                url:url,
                data: params,
                type:"post",
                error:function(){
                    obj.checked=!obj.checked
                    $(obj).attr("checked",!$(obj).attr("checked"))
                }
            })
        },
        
        toggle_permissions:function(obj,access_id,role_id,add_url,remove_url){
            var that=this
            var is_checked=this.toggle_all_permissions(obj,access_id,role_id)
            $.ajax({
                url:is_checked ? add_url : remove_url,
                type:"post",
                error:function(){
                    that.toggle_all_permissions(false,access_id,role_id,!is_checked)
                }
            })
        },

        toggle_all_permissions:function(main_obj,access_id,role_id,checked){
            var actions=['read','write','update','delete'];
            var is_checked=main_obj ? $(main_obj).attr("checked") : checked
            for(var i=0;i<actions.length;i++){
                var temp_id="#"+access_id+"-"+role_id+actions[i]
                var $obj=$(temp_id);
                if($obj.length){
                    $obj.attr("checked",is_checked)
                    $obj.attr("disabled",!is_checked)
                }
            }
            return is_checked
        },
        toggle_roles:function(chb,add_url,remove_url,token){
            $.ajax({
                url: chb.checked ? add_url : remove_url,
                data: {
                    authenticity_token: token
                },
                type: "POST",
                error:function(){
                    chb.checked=!chb.checked
                }
            })
        },
        switch_role_tabs:function(lnk,role){
            $.ajax({
                url: lnk.href,
                type: "GET",
                dataType: "html",
                success:function(data){
                    $("#role_subtree_"+role+" .role-tab a").removeClass("current-role-tab").addClass("other-role-tab")
                    $(lnk).removeClass("other-role-tab").addClass("current-role-tab")
                    $("#role_subtree_"+role).html(data)
                }
            })
            return false
        }
    }
}()


