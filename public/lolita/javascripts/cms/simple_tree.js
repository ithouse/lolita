
ITH.Tree=function(container,configuration,data){
    this.data=data
    this.container=container;
    this.DOMRoot=elementById(this.container);
    this.DOMMenuRoot=null
    this.tree=[];
    this.buttons=[]
    this.config=configuration
    this.TAB_LENGTH=7;
    this.DOMMenuRoot=ITH.Element.create("div",{className:"very-main-menu-container"})
    this.DOMRoot.appendChild(this.DOMMenuRoot)
}

ITH.Tree.arrows={
    blank:"/lolita/images/cms/arrow_blank.gif",
    east:"/lolita/images/cms/arrow_orange_e.gif",
    south:"/lolita/images/cms/arrow_orange_s.gif"
}
ITH.Tree.buttons={
    add_branch:"/lolita/images/icons/add.png",
    save_tree:"/lolita/images/icons/accept.png",
    expand:"/lolita/images/icons/edit_add.png",
    collapse:"/lolita/images/icons/edit_remove.png",
    reload_tree:"/lolita/images/icons/arrow_refresh.png"
}
ITH.Tree.prototype={
    last_button:function(){
        return this.buttons[this.buttons.length-1]
    },
    create_root_node:function(){
        var root_el=ITH.Element.create("div",{className:"menu_tree"})
        var sibling_el=ITH.Element.create("div",{
            className:"menu_sibling",
            innerHTML:"&nbsp"
        })
        var root_container_el=ITH.Element.create("div",{
            className:"menu_container",
            id:this.container+"_container"
        })
        var root_tools_el=ITH.Element.create("div",{className:"menu_tools"})
        var root_content_el=ITH.Element.create("div",{className:"menu_content"})
        var root_subtree_el=ITH.Element.create("div",{className:"menu_tree"})
        
        root_container_el.appendChild(root_tools_el)
        root_container_el.appendChild(root_content_el)
        root_container_el.appendChild(root_subtree_el)
        root_el.appendChild(sibling_el)
        root_el.appendChild(root_container_el)
        this.DOMMenuRoot.appendChild(root_el)
        return {
            parent:root_el,
            container:root_container_el,
            tools:root_tools_el,
            content:root_content_el,
            tree_element:root_subtree_el,
            sibling:sibling_el,
            tree:[{
                    parent:root_subtree_el
                }]
        }
    },
    render: function() {
        
        /* this.buttons.push(ITH.Element.create("input",{
            type:"image",
            src:ITH.Tree.buttons.expand,
            value:"Izvērts",
            title:"Parādīt visus koka zarus",
            className:"with_right_margin"
        }))
        this.last_button().style.marginLeft="30px"
        this.DOMMenuRoot.appendChild(this.last_button())
        this.buttons.push(ITH.Element.create("input",{
            type:"image",
            src:ITH.Tree.buttons.collapse,
            value:"Sakļaut",
            title:"Parādīt tikai pirmā līmeņa zarus",
            className:"with_right_margin"
        }))
        this.DOMMenuRoot.appendChild(this.last_button())*/
        var main_config=this.create_root_node()
        main_config.id=this.config.root
        main_config.path="" //ceļš, pēc tā ir redzams kā elementi ir savstarpēji saistīti
        main_config.visible=true //redzams vai neredzams, domāts izmantot lai parādītu visus elementus
        main_config.deep=0 //dziļums norāda kura līmenī ir zars
        main_config.text=null
        main_config.arrow=null
        main_config.params={}
        this.tree[0]=main_config
        //Tas jādara tā tādēl, ka 0 elements tikai pēc tā definēšanas ir pieejams
        this.tree[0].tree[0].branch=this.tree[0]; //Norāde uz vecāka elementu
        main_config.container.branch=this.tree[0];
        //Izveidoju pašu koku iekš saknes zara
        this.create_tree()
        /* this.buttons[0].tree=this
        this.buttons[1].tree=this
        this.buttons[0].onclick=function(){
            this.tree.expand_collapse(this.tree.tree[0].tree,true,false);
        }
        this.buttons[1].onclick=function(){
            this.tree.expand_collapse(this.tree.tree[0].tree,false,false);
        }*/
    },
    destroy:function(){
        this.tree=null
        this.DOMRoot.innerHTML=""
    },
    destroy_real_tree:function(tree){
        while(tree.tree_element.childNodes.length>0){
            tree.tree_element.removeChild(tree.tree_element.childNodes[0])
        }
        this.tree[0].tree=[{
                parent:this.tree[0].tree_element,
                branch:this.tree[0]
            }]
    },
    create_tree:function(){
        var current_deep=0
        this.destroy_real_tree(this.tree[0])
        for (var i=0;i<this.data.length;i++){
            var tree=this.tree;
            var parts=this.data[i].id.split("_");
            var deep=parts.length;
            //Pārbaudu vai gadījumā tekošais dziļums nav par 2 lielāks nekā iepriekšējais (neiespējams koks)
            if(deep<current_deep || deep==current_deep || deep-1==current_deep){
                current_deep=deep;
                for(var p=0;p<deep;p++){
                    tree=tree[tree.length-1].tree;
                }
                this.add_branch(tree,this.data[i])
            }else{
                break;
                throw "Nenormāls zaru izvietojums.";
            }
        }
        this.checkParentTree(this.tree);
    },
    add_branch:function(tree,data){
        //Vecāka elementu atrodu no primā zara elementa, kas vienmēr ir dots
        //Ja pirmais zars ir tukš tad tajā ievietoju elementu, ja ne,tad 
        //izveidoju jaunu zaru un tajā ievietoju elementu
        if(!tree[0].id){
            tree[0]=new ITH.Branch(this,tree[0].branch,tree[0].parent,data);
        }else{
            tree.push(new ITH.Branch(this,tree[0].branch,tree[0].parent,data))
        }
        tree[tree.length-1].render()//reāli izveidoju elementus
    },
    expand_full_tree:function(obj){
        this.expand_collapse(this.tree[0].tree,true,false)
    },
    collapse_full_tree:function(){
        this.expand_collapse(this.tree[0].tree,false,false)
    },
    expand_collapse:function(tree,expand,deep){
        for(var i=0;i<tree.length;i++){
            var branch=tree[i];
            if( branch.tree.length>1 || branch.tree[0].tools){
                if(expand){
                    //Iespējams norādīt cik dziļi atvērt vai aizvērt koku 
                    if(!deep || (deep && expand &&  branch.deep<=deep)){
                        branch.visible=true;
                        branch.toggleSubtree("opened")
                    }
                }else{
                    if(!deep || (deep &&  branch.deep>deep)){
                        branch.visible=false;
                        branch.toggleSubtree("closed")
                    }
                }
                this.expand_collapse( branch.tree,expand,deep)
            }
        }
        return;
    },
    flat_tree:function(tree){
        var result=[]
        for(var i=0;i<tree.length;i++){
            var  branch=tree[i];
            result.push( branch)
            if(branch.tree && (branch.tree.length>1 ||  branch.tree[0].tools)){
                result=result.concat(this.flat_tree( branch.tree))
            }
        }
        return result
    },
    getIdInTree:function(tree,element){
        for(var i=0;i<tree.length;i++){
            if(tree[i]===element){
                return i;
            }
        }
        return i;
    },
    real_id:function(id){
        var parts=id.split("_");
        return parts[parts.length-1]
    },
    removeElement:function(index,array){
        var temp1=array.slice(0,index);
        var temp2=array.slice(index+1);
        return temp1.concat(temp2);
    },
    //Lai nerastos situācija kad kokā nav neviena ieraksta, tad tiek izsaukta šī funkcija
    //tā nodrošina lai būtu vismaz viens ieraksts
    fillEmptyTree:function(el){
        if(el.branch.tree.length==0){
            el.branch.tree[0]={
                parent:el.branch.tree_element,
                branch:el.branch
            }
        }
    },
    
    //Pārbauda visus koka elementu lai būtu pārliecināts, ka visiem kam ir bērni ir redzama bultiņa
    //bet visiem kam nav tiem nav redzama
    checkParentTree:function(tree){
        for(var i=0;i<tree.length;i++){
            if(tree[i].tree){
                tree[i].container.className="menu_container";
                tree[i].sibling.className="menu_sibling";
                var  branch=tree[i];
                if( branch.arrow && ( branch.tree.length>1 ||  branch.tree[0].tools)){
                    if( branch.visible){
                        branch.toggleSubtree("opened")
                    }else{
                        branch.toggleSubtree("closed")
                    }
                }else{
                    if( branch.arrow){
                        branch.toggleSubtree("empty")
                    } 
                }
                this.checkParentTree(tree[i].tree)
            }else{
                return true;
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////
// custom drag and drop implementation
////////////////////ITH//////////////////////////////////////////////////////////

ITH.Branch=function(tree,branch,parent,data){
    if(!data.id.match("new")){
        var id_in_parts=data.id.split("_")
        var branch_id=id_in_parts[id_in_parts.length-1]
    }else{
        branch_id=data.id
    }
    this.parent=parent //vecāka elements HTMLDOM
    this.branch=branch //vecāka elements koka zars
    this.path=branch.path+branch_id+"_"; //ceļš, pec tā nosaka atrašanās vietu kokā kad sūta informāciju serverim
    this.visible=false;// vai zars ir redzams
    this.id=branch_id;  //zara id, skaitlis ar reālo id
    this.params=data  //visa informācija par zaru
    this.root=tree  //atsauce uz koku
    this.deep=branch.deep+1; //dziļums kādā atrodas zars
}
ITH.Branch.prototype={
    render:function(){
        //Izveidoju jaunu konteineri priekš menu ieraksta
        //Kontaineri aplieku zem parent, kas ir vecāka elementa koka elements
        //Pārējos elementus aplieku zem konteinera
        this.container=ITH.Element.create("div",{
            className:"menu_container",
            id:this.root.container+"_container_"+this.id
        })
        this.container.style.paddingLeft=(this.root.TAB_LENGTH*this.deep)+"px"
        //Izveidoju kaimiņa elementu, paredzēts lai tajā ievietotu elementu
        this.sibling=ITH.Element.create("div",{className:"menu_sibling",innerHTML:"&nbsp;",id:this.root.container+"_sibling_"+this.id})
        this.sibling.is_sibling=true
        this.sibling.root=this.root
        this.sibling.style.marginLeft=(this.root.TAB_LENGTH*this.deep)+"px";
        this.sibling.branch=this
        //pievienoju vecāka elementam
        this.parent.appendChild(this.sibling);
        this.parent.appendChild(this.container);
        
        //pievienoju rīku kontaineri un rīkus
        this.tools=ITH.Element.create("div",{className:"menu_tools"})
        this.add_tools()
        //pievienoju satura kontaineri
        this.content=ITH.Element.create("div",{className:"menu_content"})
        this.text=this.add_text_node();
        this.arrow=this.add_arrow();//Pievieno bultiņu (tukšu)
        this.tree_element=ITH.Element.create("div",{className:"menu_tree"})
        //pievienoju funkcionālos elementus kontainerim
        this.container.appendChild(this.tools)
        this.container.appendChild(this.content);
        this.container.appendChild(this.tree_element);
        this.add_mouse_move_function()
        if(this.root.draggable){
            //ja koks dragojams tad lieku zaram tādam būt un kā mērķi ir zars un kaimiņa elements
            //visi tie pievinoti kaimiņa grupai
            this.draggable=new ITH.DraggableBranch(this.root,this.container.id,this.params.menu_name)
            new YAHOO.util.DDTarget(this.container.id,this.params.menu_name);
            new YAHOO.util.DDTarget(this.sibling.id,this.params.menu_name);
        }
        //Vienmēr izveidoju jaunajam zaram savu koku ar pirmo elementu, ar vienu atribūtu
        //vecāka elementu, kas norāda vecāku,(NAV DOM elements)
        this.tree=[{
                branch:this,
                parent:this.tree_element
            }];
        this.toggleSubtree("empty")
        this.container.branch=this;
    },
    add_mouse_move_function:function(){
        //Parāda vai paslēpj tooļus
        this.tools.onmouseover=function(e){
            this.style.visibility="visible";
        }
        this.tools.onmouseout=function(e){
            this.style.visibility="hidden";
        }
        this.content.onmouseover=function(e){
            this.previousSibling.style.visibility="visible";
        }
        this.content.onmouseout=function(e){
            this.previousSibling.style.visibility="hidden";
        }  
    },
    add_text_node:function(){
        if(this.root.config.links){
            var text_node=document.createElement('a');
            if(this.params.controller.length>0) var url=this.params.controller+"/show/"+this.params.menuable_id;
            text_node.href=url || "#"
        }else{
            text_node=document.createElement('span');
        }
        text_node.innerHTML=this.params.title; 
        this.content.appendChild(text_node);
        return text_node
    },
    /*
     * Stāvokļi 
     *  0-bez bultas
     *  1-aizvērts
     *  2-atvērts
     */
    toggleSubtree:function(state){
        var state_names={"empty":0,"closed":1,"opened":2}
        for(var i=0;i<3;i++){
            this.arrow.childNodes[i].style.display="none";
        }
        this.arrow.childNodes[state_names[state]].style.display="block"
        this.tree_element.style.display=state_names[state]==2 ? "block" : "none"
    },
    //Pievienot zarama bultiņas 
    //Vienlaikus tiek ielasītas visas trīs bultiņas lai palielinātu ātrdarbību pēcāk
    add_arrow:function(){
        var arrow=ITH.Element.create("span",{className:"ith_tree_arrow"})
        var a_blank=ITH.Element.create("img",{src:ITH.Tree.arrows.blank})
        var a_e=ITH.Element.create("img",{src:ITH.Tree.arrows.east})
        var a_s=ITH.Element.create("img",{src:ITH.Tree.arrows.south})
        arrow.appendChild(a_blank);
        arrow.appendChild(a_e);
        arrow.appendChild(a_s);
        
        arrow. branch=this
        arrow.onclick=function(e){
            var self=this. branch
            if(this.firstChild.style.display!="block"){
                if(this.childNodes[1].style.display=="block"){
                    self.visible=true;
                    self.toggleSubtree("opened")
                }else{
                    if(this.childNodes[2].style.display=="block"){
                        self.visible=false;
                        self.toggleSubtree("closed")
                    }  
                }
            }
                
        };
        if(this.content.childNodes.length>0){
            var first_child=this.content.childNodes[0];
            this.content.insertBefore(arrow,first_child);
        }else{
            this.content.appendChild(arrow);
        }
        
        return arrow;
    },
    add_tools:function(){
        return false
    }
}
ITH.DraggableBranch = function(tree,id, sGroup, config) {
    ITH.DraggableBranch.superclass.constructor.call(this, id, sGroup, config);
    this.branch=tree
    Dom.setStyle(this.getDragEl(), "opacity", 0.67); // The proxy is slightly transparen
};
ITH.extend(ITH.DraggableBranch, YAHOO.util.DDProxy, {
    startDrag: function(x, y) {
        level=0;
        var dragEl = this.getDragEl();
        var clickEl = this.getEl();
        startElement=clickEl.parentNode;
        Dom.setStyle(clickEl, "visibility", "hidden");
        dragEl.innerHTML = clickEl.innerHTML;
        Dom.setStyle(dragEl, "color", Dom.getStyle(clickEl, "color"));
        Dom.setStyle(dragEl, "backgroundColor", Dom.getStyle(clickEl, "backgroundColor"));
        Dom.setStyle(dragEl, "border", "2px solid gray");
    },
    endDrag: function(e) {
        var srcEl = this.getEl();
        var proxy = this.getDragEl();
        // Show the proxy element and animate it to the src element's location
        Dom.setStyle(proxy, "visibility", "");
        var proxyElement = new YAHOO.util.Motion( 
        proxy, { 
            points: { 
                to: Dom.getXY(srcEl)
            }
        }, 
        0.2, 
        YAHOO.util.Easing.easeOut 
    )
        var proxyid = proxy.id;
        var thisid = this.id;
        // Hide the proxy and show the source element when finished with the animation
        proxyElement.onComplete.subscribe(function() {
            Dom.setStyle(proxyid, "visibility", "hidden");
            Dom.setStyle(thisid, "visibility", "");
        });
        proxyElement.animate();
        proxy_el=elementById(proxyid)
        proxy_el.innerHTML="";
    },
    getTree:function(tree){
        root=this.branch.tree[0]
        return this.getTreeInTree(root,tree);
    },
    getTreeInTree:function(root,tree){
        if(root.branch===tree){
            return root
        }else{
            for(var i=0;i<root.tree.length;i++){
                return this.getTreeInTree(root.tree[i],tree);
            }
        }
    },
    insertElementAfter:function(index,array,element){
        var temp1=array.slice(0,index+1);
        var temp2=array.slice(index+1);
        temp1[temp1.length]=element;
        return temp1.concat(temp2);
    },
    insertElementBefore:function(index,array,element){
        var temp1=array.slice(0,index);
        var temp2=array.slice(index);
        temp1[temp1.length]=element;
        return temp1.concat(temp2);
    },
    get_related_and_status:function(el){
        if(el.branch.tree.length>1){
            for(var i=0;i<el.branch.tree.length;i++){
                if(el.branch.tree[i]==el){
                    if(i>0){
                        result={
                            id:prev.id,
                            status:"next_sibling"
                        }
                    }else{
                        result={
                            id:el.branch.tree[i+1].id,
                            sattus:"prev_sibling"
                        }
                    }
                    break;
                }
                var prev=el.branch.tree[i]
            }
        }
        if(!result){
            var result={
                id:el.branch.id,
                status:"child"
            }
        }
        result.parent_id=el.branch.id
        return result
    },
    onDragDrop: function(e, id) {
        // If there is one drop interaction, the li was dropped either on the list,
        // or it was dropped on the current location of the source element.
        var elDOM=this.getEl();
        var destEl = Dom.get(id);
        if(elDOM.branch.root.parentMenu && destEl.branch.root.childMenu || (elDOM.branch.root.childMenu && destEl.is_sibling && destEl.root.parentMenu)){
            return false
        }else{
            var current_deep=YAHOO.util.DragDropMgr.interactionInfo.drop.length;
            var className=destEl.className.toLowerCase();
            if(elDOM.branch.root.childMenu && destEl. branch.root.parentMenu){
                if(current_deep==destEl. branch.deep){
                    elDOM.branch.root.add_content(elDOM.branch.id,destEl.branch.id,this.get_related_and_status(destEl.branch))
                }
            }else{
                if(current_deep==destEl.branch.deep){
                    //Ievietošana virs vai zem
                    if(className=='menu_sibling' || className=='menu_sibling colored'){
                        var el=elDOM.branch
                        destEl.parentNode.insertBefore(elDOM,destEl);
                        destEl.parentNode.insertBefore(el.sibling,elDOM);
                        //destEl.className="menu_sibling";
                        var prevSibling=elDOM.previousSibling.previousSibling;
                        //iegūstu sākotnējo atrašānās vietu kokā
                        var base_id=this.branch.getIdInTree(el.branch.tree,el);
                        el.branch.tree=this.branch.removeElement(base_id,el.branch.tree);
                        this.branch.fillEmptyTree(el);
                        var new_id=0;
                        if(prevSibling){
                            var parentEl=prevSibling.branch; 
                            el.parent=parentEl.parent;
                            el.branch=parentEl.branch;
                            el.path=parentEl.branch.path+el.id+"_";
                            el.deep=parentEl.deep;
                            new_id=this.branch.getIdInTree(el.branch.tree,prevSibling.branch);
                        }else{
                            parentEl=destEl.parentNode.parentNode.branch;
                            el.path=parentEl.path+el.id+"_";
                            el.deep=parentEl.deep+1;
                            el.branch=parentEl;
                            el.parent=parentEl.tree_element;
                        }
                        el.container.style.paddingLeft=(this.branch.TAB_LENGTH*el.deep)+"px";
                        el.sibling.style.marginLeft=(this.branch.TAB_LENGTH*el.deep)+"px";
                        if(prevSibling){
                            el.branch.tree=this.insertElementAfter(new_id,el.branch.tree,el);
                        }else{
                            parentEl.tree=this.insertElementBefore(new_id,parentEl.tree,el);  
                        }
                
                    }
                    //Ievietošana iekšā 
                    if(elDOM!=destEl &&(className=='menu_container' || className=='menu_container colored')){
                        el=elDOM.branch;
                        destEl.branch.tree_element.appendChild(elDOM.branch.sibling);
                        destEl.branch.tree_element.appendChild(elDOM);
                        //destEl.className="menu_container";
                        base_id=this.branch.getIdInTree(el.branch.tree,el);
                        el.branch.tree=this.branch.removeElement(base_id,el.branch.tree);
                        this.branch.fillEmptyTree(el);
                        el.parent=destEl;
                        el.deep=destEl.branch.deep+1;
                        el.branch=destEl.branch;
                        el.path=destEl.branch.path+el.id+"_";
                        el.container.style.paddingLeft=(this.branch.TAB_LENGTH*el.deep)+"px";
                        el.sibling.style.marginLeft=(this.branch.TAB_LENGTH*el.deep)+"px";
                        //Tools tiek izmantots tāpat vien jo tukšam zaram tāds nebūs
                        if(destEl.branch.tree[0].tools){
                            destEl.branch.tree=this.insertElementAfter(destEl.branch.tree.length-1,destEl.branch.tree,el);
                        }else{
                            destEl.branch.tree[0]=el
                        }
                    }
                }
            }
            var real=false;
            if(className=='menu_container' || className=='menu_container colored'){
                destEl.className="menu_container";
                real=true;
            }
            if (className=='menu_sibling' || className=='menu_sibling colored'){
                destEl.className="menu_sibling";
                real=true
            }
            if(real){
                this.branch.checkParentTree(this.branch.tree)
            }
            
        }
    },
    onDragOut:function(e,id){
        var destEl = Dom.get(id);
        className=destEl.className.toLowerCase();
        if (destEl) {
            if(className == "menu_container colored"){
                destEl.className="menu_container";
            }
            if (className=="menu_sibling colored"){
                destEl.className="menu_sibling";
            }
        }
    },
    onDragOver: function(e, id) {
        var srcEl = this.getEl();
        var destEl = Dom.get(id);
        // if((srcEl.branch.root.parentMenu && destEl.branch.root.childMenu) || (srcEl.branch.root.childMenu && destEl.is_sibling && destEl.root.parentMenu)) return false
        var deep=YAHOO.util.DragDropMgr.interactionInfo.over.length
        if(destEl.branch.root.childMenu) deep-=1
        var className=destEl.className.toLowerCase()
        if ((destEl &&  destEl.branch && deep==destEl.branch.deep && className == "menu_container" )|| className == "menu_sibling") {
            if (className=="menu_container"){
                destEl.className="menu_container colored";
            }
            if (className=="menu_sibling"){
                destEl.className="menu_sibling colored";
            }
            if(destEl.branch.deep>1){
                var t_deep=destEl.branch.deep
                var p_el=destEl.branch.branch.container
                while(t_deep>1){
                    p_el.className="menu_container"
                    t_deep=p_el.branch.deep
                    p_el=p_el.branch.branch.container
                }
            }
            YAHOO.util.DragDropMgr.refreshCache();
        }
    }
});