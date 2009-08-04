/*
 *TODO izveidot kontrolieri kas nosūta e-pastu nepareiza ajax pieprasījuma gadījumā
 * ar visu responsi
 */


ITH.MenuTree=function(container,configuration,data,parentMenu){
    this.draggable=true
    this.parentMenu=parentMenu //ja tiek veidots bērna elements tad šis tiek izmantots
    this.header=null
    ITH.MenuTree.superclass.constructor.call(this,container,configuration,data);
    this.contextMenu=new YAHOO.widget.ContextMenu(configuration.menu_name+"_context_menu",{
        lazyload: true,
        trigger:this.DOMMenuRoot,
        className:"menu-tree-context-menu"
    })
    this.DOMContainer=elementById(container+"_container")
    this.NEW_COUNTER=0;
    this.type="MenuTree"
    ITH.MenuTree.active[configuration.menu_type]=this
    this.TOTAL_REQUESTS=0
    this.LAST_REQUEST=""
}
ITH.MenuTree.Functions=function(){
    return{
        getCurrentMenu:function(data){
            return ITH.MenuTree.active[data.menu_type]
        },
        refreshTree:function(old_id,new_id,data){
            ITH.MenuTree.Functions.getCurrentMenu(data).refreshTreeBranch(old_id,new_id,data)
        }
    }
}()
ITH.MenuTree.translation={}
ITH.MenuTree.images={
    move:"/lolita/images/icons/move.png",
    trash:"/lolita/images/cms/trash.gif",
    published:"/lolita/images/cms/published.gif",
    unpublished:"/lolita/images/cms/unpublished.gif",
    eraser:"/lolita/images/icons/eraser.png",
    edit:"/lolita/images/icons/edit.png",
    add_public:"/lolita/images/icons/add.png"
}
ITH.MenuTree.colors={
    new_item:"gray",
    existing_item:"#0091B9",
    unused_item:"green"
}
ITH.MenuTree.paths={
    public_menus:"/admin/menu/public_menus",
    public_menu:"/admin/menu/public_menu",
    delete_public_menu:"/admin/menu/delete_public_menu",
    add_content:"/admin/menu/add_content",
    remove_content:"/admin/menu/remove_content/",
    get_updated_items:"/admin/menu/get_updated_items",
    publish:"/admin/menu/toggle_published/",
    refresh:"/admin/menu/refresh",
    save:'/admin/menu/save_full_tree',
    update:'/admin/menu_item/edit',
    create:"/admin/menu_item/new"
}
/*
 * Vienlaikus var būt aktīvas tikai divu tipu izvēlnes
 * Aplikācijas izvēlne ar navigāciju attiecīgajā vārdkopā 
 * Web izvēlne, kas atbilst Cms sadaļai, bet teorētiski varētu arī būt citur
 */
ITH.MenuTree.active={
    "app":null,
    "web":null
}
ITH.extend(ITH.MenuTree,ITH.Tree,{
    doRequest:function(method,url,callback,params){
        //TODO pielikt lai dzēš vecos pieprsījumus ja ir jauns svaigs pieprasījums, tjipa
        //lai tie kas atkārtojas to vairs nedara
        if(url!=this.LAST_REQUEST){
            this.LAST_REQUEST=url
            this.TOTAL_REQUESTS=1
        }else{
            this.TOTAL_REQUESTS+=1
        }
        
        if(this.TOTAL_REQUESTS==3){
            this.TOTAL_REQUSTS=0
            this.LAST_REQUEST=""
            ITH.Cms.wait.hide(true);
        }else{
            this.header.loading.style.display="block"
            complete=function(type,args){
                var conn=args[0].conn
                var self=args[1].self
                if(conn.status==200 || self.TOTAL_REQUESTS==2){
                    self.header.loading.style.display="none"
                    if(args[1].method.toUpperCase()=="GET" && self.TOTAL_REQUESTS<2){
                        self.hide();
                    }
                    if(conn.status==200) self.TOTAL_REQUESTS=0
                }
            }
            if(!callback.argument){
                callback.argument={}
            }
            callback.argument.self=this
            callback.argument.method=method.toUpperCase()
            if(method.toUpperCase()!="GET"){
                params=params && params.length>0 ? (params[params.length-1]=="&" ? params+"is_ajax=true" : params+"&is_ajax=true") : "is_ajax=true"
            }else{
                var symb=url.search(/\?/)>-1 ? (url[url.length-1]=="&" ? "" : "&") : "?"
                url=url+symb+"is_ajax=true"
            }
            YAHOO.util.Connect.completeEvent.subscribe(complete); 
            YAHOO.util.Connect.asyncRequest(method, url, callback,params || "");
        }
        
    },
    before_last_button:function(){
        return this.buttons[this.buttons.length-2]
    },
    render:function(){
        if(this.config.accessable){
            this.add_context_menu_events()
            this.add_context_menu_items()
            ITH.MenuTree.superclass.render.call(this)
            this.createHeader()
            this.add_buttons();
            
            this.contextMenu.render(this.DOMMenuRoot)
        }
        if(this.config.menu_type=="web"){
            this.add_child_menu()
        }
        this.sideMenu=new ITH.SideMenu(this.config.menu_type+"_menu",this)
    },
    onMenuShow:function(type,args){
    /*var branch=null
        var oTarget = this.contextEventTarget, 
	            aMenuItems, 
	            aClasses; 
        if(oTarget.parent){
            branch=oTarget.parent
        }else if(oTarget.configuration){
            branch=oTarget.configuration
        }else if(oTarget.parentNode && oTarget.parentNode.parent){
            branch=oTarget.parentNode.parent
        }else if(oTarget.parentNode && oTarget.parentNode.configuration){
            branch=oTarget.parentNode.configuration
        }
        
        
        var b=this.getRoot()
        var c=1*/
    },
    add_context_menu_events:function(){
        this.contextMenu.subscribe("triggerContextMenu",this.onMenuShow)
    },
    add_context_menu_items:function(){
        this.contextMenu.addItems([
            [
            {
                text:ITH.MenuTree.translation.expand_menu,
                onclick:{
                    fn:this.expand_full_tree,
                    obj:this,
                    scope:this
                }
            },

            {
                text:ITH.MenuTree.translation.collapse_menu,
                onclick:{
                    fn:this.collapse_full_tree,
                    obj:this,
                    scope:this
                }
            },

            {
                text:ITH.MenuTree.translation.refresh,
                onclick:{
                    fn:this.refresh,
                    obj:this,
                    scope:this
                }
            }
            ]
            ])
    },
    add_buttons:function(){
        // this.before_last_button().style.marginLeft="" //noņemu marginu lai pieliktu jaunajai pogai
        this.buttons.push(ITH.Element.create("input",{
            type:"image",
            src:ITH.Tree.buttons.add_branch,
            value:ITH.MenuTree.translation.add_button,
            title:ITH.MenuTree.translation.add_button_title,
            className:"with_right_margin"
        }))
        this.last_button().menu=this
        this.last_button().onclick=function(){
            this.menu.NEW_COUNTER+=1
            this.menu.add_branch(this.menu.tree[0].tree,this.menu.default_configuration())
        }
        this.DOMMenuRoot.insertBefore(this.last_button(),this.tree[0].parent)
        this.buttons.push(ITH.Element.create("input",{
            type:"image",
            src:ITH.Tree.buttons.save_tree,
            value:ITH.MenuTree.translation.save_button,
            title:ITH.MenuTree.translation.save_button_title,
            className:"with_right_margin"
        }))
        this.DOMMenuRoot.insertBefore(this.last_button(),this.before_last_button())
        this.last_button().style.marginLeft="30px"
        this.last_button().menu=this
        this.last_button().onclick=function(){
            this.menu.save(this.menu.tree[0].tree)
        };
        this.buttons.push(ITH.Element.create("input",{
            type:"image",
            src:ITH.Tree.buttons.reload_tree,
            value:ITH.MenuTree.translation.refresh,
            title:ITH.MenuTree.translation.refresh_button_title,
            className:"with_right_margin"
        }))
        this.DOMMenuRoot.insertBefore(this.last_button(),this.tree[0].parent)
        YAHOO.util.Event.addListener(this.last_button(),"click",this.refresh,this,true)
    },
    add_branch:function(tree,data){
        if(!tree[0].id){
            tree[0]=new ITH.MenuBranch(this,tree[0].branch,tree[0].parent,data);
        }else{
            tree.push(new ITH.MenuBranch(this,tree[0].branch,tree[0].parent,data))
        }
        tree[tree.length-1].render()//reāli menuBranch izveidoju elementus
    },
    add_child_menu:function(){
        var requestHandler={
            success:function(request){
                var self=request.argument.self
                var menus=eval(request.responseText)
                var select=self.child_list(menus)
                self.add_delete_public_menu(select)
            },
            failure:function(request){
                if(request.status!=404){
                    request.argument.self.add_child_menu()
                }
            }
        }
        this.doRequest('POST',ITH.MenuTree.paths.public_menus, requestHandler,"namespace="+this.config.module_name);
    },
    add_branches_to_child_group:function(){
        if(this.childMenu){
            var tree_arr=this.flat_tree(this.tree[0].tree) 
            for(var i=0;i<tree_arr.length;i++){
                if (tree_arr[i].draggable) tree_arr[i].draggable.addToGroup(this.childMenu.config.menu_name)
            }
        }
    },
    destroy_child_menu:function(){
        if(this.childMenu){
            var parent=this.childMenu.DOMMenuRoot.parentNode
            parent.removeChild(this.childMenu.DOMMenuRoot)
            this.childMenu=null
        }
    },
    change_child_menu:function(e){
        if(this.childSelect.value>0 && (!this.childMenu || (this.childMenu && this.childMenu.config.menu_id!=this.childSelect.value))){
            var requestHandler={
                success:function(request){
                    var args=eval(request.responseText)
                    request.argument.self.destroy_child_menu()
                    request.argument.self.childMenu=new ITH.MenuTree(request.argument.self.container,args[0],args[1],request.argument.self)
                    request.argument.self.childMenu.render()
                    request.argument.self.add_branches_to_child_group()
                },
                failure:function(request){
                    if(request.status!=404){
                        request.argument.self.change_child_menu()
                    }
                }
            }
            this.doRequest('POST',ITH.MenuTree.paths.public_menu, requestHandler,"id="+this.childSelect.value);
        }
    },
    child_list:function(menus){
        var select_container=ITH.Element.create("div",{
            className:"child-menu-select-container"
        })
        select_container.innerHTML=ITH.MenuTree.translation.public_menu+" "
        //Izveidoju sarakstu ar izvēlnēm
        var select=ITH.Element.create("select",{
            className:"child-menu-select"
        })
        this.childSelect=select //tikai vecāka elementam
        YAHOO.util.Event.addListener(select,"change",this.change_child_menu,this,true)
        for(var i=0;i<menus.length;i++){
            var option=ITH.Element.create("option",{
                value:menus[i].id,
                innerHTML:menus[i].name
            })
            select.appendChild(option)
        }
        select_container.appendChild(select)
        //beidzas saraksta izveide
        this.DOMRoot.insertBefore(select_container,this.DOMRoot.childNodes[0])
        return select_container
    },
    add_delete_public_menu:function(sel_container){
        var add=ITH.Element.create("img",{
            src:ITH.MenuTree.images.add_public,
            className:"menu-small-buttons"
        })
        YAHOO.util.Event.addListener(add,"click",this.add_public_menu,this,true)
        var remove=ITH.Element.create("img",{
            src:ITH.MenuTree.images.trash,
            className:"menu-small-buttons"
        })
        YAHOO.util.Event.addListener(remove,"click",this.remove_public_menu,this,true)
        sel_container.appendChild(add)
        sel_container.appendChild(remove)
    },
    add_public_menu:function(){
        if(!ITH.MenuTree.menu_dialog){
            Dom.get('public_menu_dialog').style.display=""
            var handleSubmit=function(){
                this.submit()
            }
            var handleCancel=function(){
                this.cancel()
            }
            ITH.MenuTree.menu_dialog = new YAHOO.widget.Dialog("public_menu_dialog",  
            {
                width : "300px",
                fixedcenter : true, 
                visible : false,  
                modal:true,
                draggable: false, 
                buttons : [ { 
                    text:ITH.MenuTree.translation.dialog_make,
                    handler:handleSubmit,
                    isDefault:true
                },

                {
                    text:ITH.MenuTree.translation.dialog_cancel,
                    handler:handleCancel
                } ]
            })
            var requestHandler={
                success:function(request){
                    ITH.MenuTree.menu_dialog.hide()
                    var conf=eval(request.responseText)[0]
                    var self=request.argument.caller
                    var option=ITH.Element.create("option",{
                        innerHTML:conf.name,
                        value:conf.id
                    })
                    self.childSelect.appendChild(option)
                    self.childSelect.selectedIndex=self.childSelect.options.length-1
                    self.change_child_menu()
                },
                failure:function(request){
                    if(request.status==500){
                        alert(request.responseText)
                    }else{
                        if(request.status!=404){
                            ITH.MenuTree.menu_dialog.submit()
                        }
                    }
                },
                argument:{
                    caller:this
                }
            }
            ITH.MenuTree.menu_dialog.callback=requestHandler
            ITH.MenuTree.menu_dialog.render()
        }
        ITH.MenuTree.menu_dialog.show()
    },
    remove_public_menu:function(){
        var requestHandler={
            success:function(request){
                var self=request.argument.self
                var option=ITH.Element.optionByValue(self.childSelect.options,request.argument.id)
                if(option){
                    self.childSelect.removeChild(option)
                    self.destroy_child_menu()
                }
            },
            failure:function(request){
                if(request.status!=404){
                    request.argument.self.remove_public_menu()
                }
            },
            argument:{
                id:this.childSelect.value
            }
        }
        this.doRequest('POST',ITH.MenuTree.paths.delete_public_menu, requestHandler,"id="+this.childSelect.value);
    },
    add_content:function(content_id,public_id,parent){
        var requestHandler={
            success:function(request){
                var self=request.argument.self
                var args=eval(request.responseText)
                var new_item=args[0]
                args.shift()
                for(var i=0;i<args.length;i++){
                    var real_old_id=self.real_id(args[i].id)
                    var old_branch=self.getByRealId(self.childMenu.tree[0].tree,real_old_id)
                    old_branch.id=real_old_id
                    old_branch.params=args[i]
                    old_branch.refresh()
                }
                var child_branch=self.getByRealId(self.childMenu.tree[0].tree,request.argument.public_id)
                child_branch.params=new_item
                var id=self.real_id(new_item.id)
                child_branch.id=id
                child_branch.refresh()
            },
            failure:function(request){
                if(request.status!=404){
                    request.argument.self.add_content(request.argument.content_id,request.argument.public_id,request.argument.parent)
                }
            },
            argument:{
                content_id:content_id,
                public_id:public_id,
                parent:parent
            }
        }
        var params=json_to_params({
            content_id:content_id,
            public_id:public_id,
            public_parent_id:parent.id,
            status:parent.status,
            parent_id:parent.parent_id
        })
        this.doRequest('POST',ITH.MenuTree.paths.add_content, requestHandler,params);
    },
    get_updated_items:function(){
        var requestHandler={
            success:function(request){
                var args=eval(request.responseText)
                request.argument.self.config.current_time=args[0]
                var updated_items=args[1]
                for(var i=0;i<updated_items.length;i++){
                    request.argument.self.refreshTreeBranch(updated_items[i][0],updated_items[i][1],updated_items[i][2],true)
                }
            },
            failure:function(request){
                request.argument.self.get_updated_items()
            }
        }
        this.doRequest("POST",ITH.MenuTree.paths.get_updated_items,requestHandler,"current_time="+this.config.current_time+"&menu_id="+this.config.menu_id)
    },
    hide_all_menus:function(){
        if(ITH.MenuTree.active.app){
            ITH.MenuTree.active.app.DOMContainer.style.display="none"
        }
        if(ITH.MenuTree.active.web){
            ITH.MenuTree.active.web.DOMContainer.style.display="none"
        }
    },
    show:function(){
        elementById('content').style.display="none"
        this.hide_all_menus()
        this.DOMContainer.style.display="block";
    },
    hide:function(){
        this.hide_all_menus()
        elementById('content').style.display="block"
    },
    refresh:function(){
        var requestHandler={
            success: function(request){
                request.argument.self.data=eval(request.responseText)
                request.argument.self.create_tree();
                request.argument.self.sideMenu.refresh()
                if(request.argument.self.childMenu) request.argument.self.childMenu.refresh()
            },
            failure:function(request){
                if(request.status!=404){
                    request.argument.self.refresh()
                }
            }
        };
        this.doRequest('POST',ITH.MenuTree.paths.refresh, requestHandler,"id="+this.config.menu_id);
    },
    refresh_child_menu:function(branch,data){
        if(this.childMenu){
            var child_branch=this.getByContent(this.childMenu.tree[0].tree,branch.params.menuable_type,branch.params.menuable_id,branch.params.id)
            if(child_branch){
                if(data){ //mainu satura datus, ja mainījies vecāka zars
                    child_branch.params.controller=data.controller
                    child_branch.params.action=data.action
                    child_branch.params.menuable_type=data.menuable_type
                    child_branch.params.menuable_id=data.menuable_id
                    child_branch.params.published=data.published
                }else{ // mainu tikai publiskošanas stāvokli, ja mainījies vecāka stāvoklis
                    child_branch.params.published=branch.params.published
                }
                child_branch.refresh()
            }
        }
    },
    createHeader:function(){
        var container=ITH.Element.create("div",{
            className:"menu-title-container"
        })
        container.style.height="25px"
        var title=ITH.Element.create("div",{
            className:"big blue",
            innerHTML:this.parentMenu ? ITH.MenuTree.translation.public_menu+" " : ITH.MenuTree.translation.menu+" "+this.config.menu_name
        })
        title.style.cssFloat="left"
        var loading=ITH.Element.loading("small")
        loading.style.display="none"
        container.titleContainer=title
        container.loading=loading
        container.appendChild(title)
        container.appendChild(loading)
        this.DOMMenuRoot.insertBefore(container,this.DOMMenuRoot.childNodes[0])
        this.header=container
    },
    
    getByRealId:function(tree,id){
        for(var i=0;i<tree.length;i++){
            if(tree[i].id==id){
                return tree[i]
            }else{
                if(tree[i].tree.length>1 || tree[i].tree[0].tools){
                    var branch=this.getByRealId(tree[i].tree,id);
                    if (branch){
                        return branch;
                    }
                }
            }
        }
        return false
    },
    getByContent:function(tree,menuable_type,menuable_id,id){
        id=this.real_id(id)
        for(var i=0;i<tree.length;i++){
            if((tree[i].params.menuable_type==menuable_type && tree[i].params.menuable_id==menuable_id) || (tree[i].params.menuable_type=="Admin::MenuItem" && tree[i].params.menuable_id==parseInt(id))){
                return tree[i]
            }else{
                if(tree[i].tree.length>1 || tree[i].tree[0].tools){
                    var branch=this.getByContent(tree[i].tree,menuable_type,menuable_id,id);
                    if (branch){
                        return branch;
                    }
                }
            }
        }
        return false
    },
    refreshTreeBranch:function(old_id,new_id,data,only_refresh){
        if(!only_refresh)this.show()
        var branch=this.getByRealId(this.tree[0].tree,old_id);
        if(branch){
            branch.id=new_id.toString()
            this.refresh_child_menu(branch,data) //atjaunoju bērna koku, ja gadījumā tajā ir šāda tipa elements, lai tas atjaunotos, neatjaunojot koku
            branch.params=data
            branch.refresh()
        }
    },
    getTreeIds:function(tree){
        var arr=[];
        for(var i=0;i<tree.length;i++){
            var branch=tree[i];
            var parent_id=branch.branch.id
            arr[arr.length]=[branch.id,parent_id]
            try{
                if(branch.tree.length>1 || branch.tree[0].tools){
                    arr=arr.concat(this.getTreeIds(branch.tree));
                }
            }catch(err){}
        }
        return arr;
    },
    
    save:function(tree){
        var result_tree=this.getTreeIds(tree)
        var result="";
        for(var i=0;i<result_tree.length;i++){
            result+="tree[]="+result_tree[i][0]+"&"
            result+="tree[]="+result_tree[i][1]+"&"
        }
        var requestHandler={
            success:function(request){
                request.argument.caller.sideMenu.refresh();
                request.argument.caller.refresh();
            },
            failure:function(request){
                if(request.status!=404){
                    request.argument.caller.save(request.argument.tree)
                }
            },
            argument:{
                caller:this,
                tree:tree
            }
        };
        this.doRequest('POST', ITH.MenuTree.paths.save, requestHandler,result+"&menu_name="+this.config.menu_name);
    },
    default_configuration:function(current){
        var defaults={
            id:"new"+(this.NEW_COUNTER),
            title:ITH.MenuTree.translation.no_title,
            menuable_id:0,
            menuable_type:null,
            published:false,
            controller:"",
            action:"",
            menu_type:this.config.menu_type,
            module_name:this.config.module_name,
            module_type:this.config.module_type
        }
        if(current){
            for(var i in current){
                defaults[i]=current[i]
            }
        }
        return defaults
    }
})
ITH.MenuBranch=function(tree,branch,parent,data){
    ITH.MenuBranch.superclass.constructor.call(this,tree,branch,parent,data)
}
ITH.extend(ITH.MenuBranch,ITH.Branch,{
    doRequest:function(method,url,callback,params){
        this.root.doRequest(method,url,callback,params)
    },
    refresh:function(){
        if(this.tools.publish_tool) this.tools.publish_tool.src=this.params.published ? ITH.MenuTree.images.published : ITH.MenuTree.images.unpublished
        if(this.root.childMenu){
            // this.refresh_child_branch(this.root.childMenu.tree[0].tree,this.params.menuable_type,this.params.menuable_id,this.params.id,this.params.published)
            var child_branch=this.root.getByContent(this.root.childMenu.tree[0].tree,this.params.menuable_type,this.params.menuable_id,this.params.id)
            if(child_branch){
                child_branch.params.published=this.params.published
                child_branch.refresh()
            }
        }
        this.text.refresh()
    },
    remove_content:function(params){
        this.params=params
        this.refresh()
    },
    //Pievieno tūļus
    //Kustināšanas un dzēšanas pogas
    //Dzēšanas funkcija izsauc fill_empty_tree, lai neatstātu koku tukšu (domāts js koku nevis DOM)
    //un arī checkParentTree, lai tekošajam kokam noņemtu visas bultiņas ja nepieciešams
    add_move_tool:function(){
        var move_el=document.createElement('img');
        move_el.src=ITH.MenuTree.images.move
        return move_el
    },
    add_delete_tool:function(){
        var delete_el=document.createElement('img');
        delete_el.title=ITH.MenuTree.translation.delete_branch
        delete_el.src=ITH.MenuTree.images.trash
        delete_el.tree=this.root
        delete_el.onclick=function(e){
            var container=this.parentNode.parentNode;
            var parent=container.parentNode;
            var el=container.branch;
            //pārceļu iepriekšējā nākošu uz tekošā nākošo
            var prevSibling=container.previousSibling.previsousSibling
            if(prevSibling){
                prevSibling.branch.sibling=el.sibling
            }
            var base_id=this.tree.getIdInTree(el.branch.tree,el);
            el.branch.tree=this.tree.removeElement(base_id,el.branch.tree);
            this.tree.fillEmptyTree(el);
            var p_tree=el;
            for(var ee=1;ee<el.deep;ee++){
                p_tree=p_tree.branch
            }
            p_tree=p_tree.tree;
            this.tree.checkParentTree(p_tree);
            var sibling=el.sibling;
            parent.removeChild(sibling);
            parent.removeChild(container);
        };
        return delete_el
    },
    add_publish_tool:function(){
        var publish=document.createElement('img');
        if(this.params.published){
            publish.src=ITH.MenuTree.images.published;
        }else{
            publish.src=ITH.MenuTree.images.unpublished;
        }
        publish.title=ITH.MenuTree.translation.publish_branch
        publish.branch=this
        publish.onclick=function(e){
            if(!this.parentNode.parentNode.branch.id.toString().match("new")){
                var requestHandler={
                    success: function(request){
                        var branch=request.argument.caller.branch
                        branch.params.published=parseInt(request.responseText)>0 ? true : false
                        branch.refresh()
                    },
                    failure:function(request){
                        if(request.status!=404){
                            request.argument.caller.onclick.call(request.argument.caller)
                        }
                    },
                    argument:{
                        caller:this
                    }
                };
                this.branch.doRequest("post", ITH.MenuTree.paths.publish, requestHandler,"id="+this.parentNode.parentNode.branch.id);
            }
        }
        return publish
    },
    add_remove_content_tool:function(){
        var remove_content=document.createElement('img');
        remove_content.src=ITH.MenuTree.images.eraser;
        remove_content.title=ITH.MenuTree.translation.remove_branch_link
        remove_content.branch=this
        remove_content.onclick=function(e){
            if(!this.parentNode.parentNode.branch.id.toString().match("new")){
                var requestHandler={
                    success:function(request){
                        var self=request.argument.caller.parentNode.parentNode.branch
                        if(self.root.childMenu){
                            var child_branch=self.root.getByContent(self.root.childMenu.tree[0].tree,self.params.menuable_type,self.params.menuable_id,self.params.id)
                            child_branch.remove_content(request.argument.self.default_configuration({
                                id:child_branch.id,
                                title:child_branch.params.title,
                                menuable_type:"Admin::MenuItem",
                                menuable_id:self.id
                            }))
                        }
                        self.remove_content(request.argument.self.default_configuration({
                            id:self.id,
                            title:self.params.title
                        }))
                        
                    },
                    failure:function(request){
                        if(request.status!=404){
                            request.argument.caller.onclick.call(request.argument.caller)
                        }
                    },
                    argument:{
                        caller:this
                    }
                };
                this.branch.doRequest('POST', ITH.MenuTree.paths.remove_content+this.parentNode.parentNode.branch.id, requestHandler);
            }
        }  
        return remove_content
    },
    add_edit_tool:function(){
        var add_content=document.createElement('img');
        add_content.src=ITH.MenuTree.images.edit;
        add_content.title=ITH.MenuTree.translation.edit_branch_content
        add_content.branch=this
        add_content.onclick=function(e){
            var branch=this.parentNode.parentNode.branch;
            var url="/"
            if(branch.id.toString().match("new")){
                url+=branch.params.controller+"/"+branch.params.action
            }else{
                url+=branch.params.controller+"/"+branch.params.action
                if(branch.params.action!="create") url+="/"+branch.params.menuable_id
            }
            url+="?menu_item_id="+branch.id
            if(branch.params.controller.length>1){
                var requestHandler={
                    success:function(request){
                        $('#content').html(request.responseText)
                    },
                    failure:function(request){
                        if(request.status!=404){
                            request.argument.caller.onclick.call(request.argument.caller)
                        }
                    },
                    argument:{
                        caller:this
                    }
                };
                this.branch.doRequest('GET', url, requestHandler);
            }
        }
        return add_content
    },
    add_tools:function(){
        this.tools.move_tool=this.add_move_tool()
        this.tools.appendChild(this.tools.move_tool)
        this.tools.delete_tool=this.add_delete_tool() 
        if(this.params.module_type=='web'){
            this.tools.publish_tool=this.add_publish_tool();
            this.tools.remove_content_tool=this.add_remove_content_tool()
            this.tools.appendChild(this.tools.publish_tool)
            this.tools.appendChild(this.tools.remove_content_tool)
            this.tools.edit_tool=this.add_edit_tool()
            this.tools.appendChild(this.tools.edit_tool)
        }
        this.tools.appendChild(this.tools.delete_tool)
    },
    add_text_node:function(){
        var text_node=ITH.Element.create("span",{
            className:"menu_content_text"
        })
        text_node.branch=this
        text_node.refresh=function(){
            this.innerHTML=this.branch.params.title;
            if(this.branch.id.match("new") || this.branch.params.menuable_type==null){
                this.style.color=ITH.MenuTree.colors.new_item;
            }else{
                if(this.branch.params.menuable_id>0 && this.branch.params.menuable_type!="Admin::MenuItem"){
                    this.style.color=ITH.MenuTree.colors.existing_item
                }else{
                    this.style.color=ITH.MenuTree.colors.unused_item;
                } 
            }
        }
        text_node.title=ITH.MenuTree.translation.edit_branch
        YAHOO.util.Event.addListener(text_node,"click",this.onTextClick,text_node,true);
        this.content.appendChild(text_node);
        text_node.refresh()
        return text_node
    },
    onTextClick:function(e){
        var branch=this.parentNode.parentNode.branch;
        var self=this.branch.root
        if(branch.id.match("new")){
            var url=ITH.MenuTree.paths.create
            var parent_id=branch.branch.id
            var move_right=false;
            var sibling=branch.container.previousSibling.previousSibling;
            if(sibling){
                parent_id=sibling.branch.id;
                move_right=true;
            }
            var params=json_to_params({
                id:               branch.id,
                old_menu_item_id: branch.id,
                parent_element_id:parent_id,
                menu_id:          self.config.menu_id,
                move_to_id:       move_right,
                menu_type:        branch.params.menu_type
            })
        }else{
            params=json_to_params({
                id:branch.id,
                old_menu_item_id:branch.id,
                menu_type:branch.params.menu_type,
                menu_id:self.config.menu_id
            })
            url=ITH.MenuTree.paths.update
        }
        url=url+"?"+params
        var requestHandler={
            success:function(request){
                request.argument.self.hide()
                $('#content').html(request.responseText);
            },
            failure:function(request){
                if(request.status!=404){
                    request.argument.caller.onTextClick.call(request.argument.text)
                }
            },
            argument:{
                caller:this.branch,
                text:this
            }
        };
        self.doRequest("GET",url,requestHandler,params)
    }
})
ITH.SideMenu=function(container,tree){
    this.mainMenu=tree
    this.container=container
    this.item_container=container+"_items"
    this.tree=[]
    this.refresh();
}
ITH.SideMenu.prototype={
    refresh:function(){
        if(!this.mainMenu.parentMenu){
            var item_element=elementById(this.item_container);
            item_element.title=ITH.MenuTree.translation.manage_content_tree
            var first_level=this.mainMenu.tree[0].tree
            item_element.innerHTML=""
            this.createTree(first_level,item_element,0)
            if(this.mainMenu.config.accessable){
                this.createFooter(item_element)
            }
        }
    },
    createTree:function(tree,container,level){
        for(var i=0;i<tree.length;i++){
            var branch_container=ITH.Element.create("div",{
                className:"item"
            })
            if(tree[i].tree){
                this.createBranch(branch_container,tree[i])
                this.tree.push({
                    container:branch_container,
                    level:level
                })
            }
            
            container.appendChild(branch_container)
        } 
    },
    createBranch:function(container,branch,level){
        if(level<1){
            container.style.paddingBottom="5px"
        }
        var arrow=document.createElement("img")
        arrow.src=branch.tree.length>1 || branch.tree[0].tools ? ITH.Tree.arrows.east : ITH.Tree.arrows.blank
        arrow.branch=branch
        arrow.onclick=function(e){
            if(branch.tree.length>1 || branch.tree[0].tools){
                if(this.src.match(ITH.Tree.arrows.east)){
                    this.src=ITH.Tree.arrows.south
                    this.subtree.style.display="block"
                }else{
                    this.src=ITH.Tree.arrows.east
                    this.subtree.style.display="none"
                }
            }
        }
        var text=document.createElement("span")
        text.innerHTML=branch.params.title
        if(branch.params.action.length>0 && branch.params.module_type=="app"){
            var url=branch.params.controller+"/"+branch.params.action
        }else{
            if(parseInt(branch.params.menuable_id)>0 && branch.params.module_type=="web"){
                url="/"+branch.params.controller+"/"+branch.params.action+"/"+branch.params.menuable_id
            }
        }
        text.root_object=this
        text.parent=container
        container.text=text
        if(url){
            text.onclick=function(){
                ITH.Cms.wait.show();
                var requestHandler={
                    success:function(request){
                        $('#content').html(request.responseText)
                        ITH.Cms.wait.hide()
                    },
                    failure:function(request){
                        ITH.Cms.wait.hide();
                        if(request.status!=404){
                            request.argument.text.onclick.call(request.argument.text)
                        } 
                    },
                    argument:{
                        text:this
                    }
                };
               // this.root_object.mainMenu.doJQRequest("GET",url,requestHandler,text.onclick)
                this.root_object.mainMenu.doRequest('GET', url, requestHandler); 
            }
        }
        var content=ITH.Element.create("div",{
            className:"left-menu-item"
        })
        content.appendChild(arrow)
        content.appendChild(text)
        var splitter=ITH.Element.create("div",{
            className:"splitter"
        })
        var subtree=ITH.Element.create("div",{
            className:"child-containter"
        })
        subtree.style.display="none"
        arrow.subtree=subtree
        container.appendChild(content)
        container.appendChild(splitter)
        container.appendChild(subtree)
        subtree.parent=container //lai zinot tekošo var atrast visus kas virs viņa
        if(branch.tree.length>1 || branch.tree[0].tools){
            this.createTree(branch.tree,subtree,level+1)
        }
    },
    createFooter:function(container){
        var footer=ITH.Element.create("div",{
            className:"edit-menu"
        })
        var text=ITH.Element.create("span",{
            innerHTML:this.mainMenu.config.menu_type=="web" ? ITH.MenuTree.translation.edit_content : ITH.MenuTree.translation.edit_menu
        })
        text.menu=this
        text.onclick=function(){
            this.menu.mainMenu.get_updated_items();
            this.menu.mainMenu.show()
        }
        footer.appendChild(text)
        container.appendChild(footer)
    },
    show_current:function(current){
        var counter=0
        while(counter<this.tree.length){
            this.tree[counter].container.text.style.color="#1780B0"
            counter+=1;
        }
        current.text.style.color="#F48843"
    }
  
}