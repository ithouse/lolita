var MAP_CONTAINER={};
function content_map(data,container,configuration) {
    var DATA=data
    var startElement=null;
    var DDList=YAHOO.example.DDList
    var Dom = YAHOO.util.Dom;
    var Event = YAHOO.util.Event;
    var DDM = YAHOO.util.DragDropMgr;
    MAP_CONTAINER.container=container;
    MAP_CONTAINER.tree=[];
    MAP_CONTAINER.config=configuration
    MAP_CONTAINER.TAB_LENGTH=10;
    MAP_CONTAINER.NEW_COUNTER=0;
    MAP_CONTAINER.color={
        nc:"gray",
        ec:"#0091B9",
        ulc:"green"
    }
YAHOO.example.DDApp = {
    init: function() {
        var parent=elementById(MAP_CONTAINER.container);
            var expand=document.createElement('input');
                expand.type="button";
                expand.value="Izvērst";
                expand.className="btn with_right_margin";
            var collapse=document.createElement('input');
                collapse.type="button";
                collapse.value="Sakļaut";
                collapse.className="btn with_right_margin";
            parent.appendChild(expand);
            parent.appendChild(collapse);
            var root_node=document.createElement('div');
                root_node.className="menu_tree";
                var root_node_container=document.createElement('div');
                    root_node_container.className="menu_container";
                    root_node_container.id=MAP_CONTAINER.container+"_container";
                    var root_node_tools=document.createElement('div');
                        root_node_tools.className="menu_tools";
                    var root_node_content=document.createElement('div');
                        root_node_content.className="menu_content";
                    var root_node_tree=document.createElement('div');
                        root_node_tree.className="menu_tree";
                
                root_node_container.appendChild(root_node_tools);
                root_node_container.appendChild(root_node_content);
                root_node_container.appendChild(root_node_tree);
            root_node.appendChild(root_node_container);
        parent.appendChild(root_node);
        
        
        new YAHOO.util.DDTarget(MAP_CONTAINER.container+"_menu_root_container");
        MAP_CONTAINER.tree[0]={
            parent:root_node,   //norāda uz HTML DOM elementu kas ir viss koks
            id:MAP_CONTAINER.config.root,  //konteinera id
            path:"",    //ceļš, pēc tā ir redzams kā elementi ir savstarpēji saistīti
            visible:true,   //redzams vai neredzams, domāts izmantot lai parādītu visus elementus
            deep:0,         //dziļums norāda kura līmenī ir zars
            container:root_node_container,  //HTML DOM elements uz konteineri
            tools:root_node_tools,  //HTML DOM elements uz tools
            content:root_node_content,  //HTML DOM elements uz content
            tree_element:root_node_tree,    //HTML DOM elements uz koku
            text:null,
            arrow:null,
            root_elements:[expand,collapse,root_node],
            params:{},
            tree:[{ //KOKS, katram elementam ir koks
                parent:root_node_tree   //norāda uz HTML DOM elementu kas ir viss koks vecāka koks
            }]
        };
        //Tas jādara tā tādēl, ka 0 elements tikai pēc tā definēšanas ir pieejams
        MAP_CONTAINER.tree[0].tree[0].parentNode=MAP_CONTAINER.tree[0]; //Norāde uz vecāka elementu
        root_node_container.configuration=MAP_CONTAINER.tree[0];
        var current_deep=0;
        for (var i=0;i<DATA.length;i++){
            var current_branch=MAP_CONTAINER.tree;
            var parts=DATA[i].id.split("_");
            var branch_id=parts[parts.length-1];
            var deep=parts.length;
            //Pārbaudu vai gadījumā tekošais dziļums nav par 2 lielāks nekā iepriekšējais (neiespējams koks)
            if(deep<current_deep || deep==current_deep || deep-1==current_deep){
                current_deep=deep;
                for(var p=0;p<deep;p++){
                    current_branch=current_branch[current_branch.length-1].tree;
                }
                //Vecāka elementu atrodu no primā zara elementa, kas vienmēr ir dots
                //Ja pirmais zars ir tukš tad tajā ievietoju elementu, ja ne,tad 
                //izveidoju jaunu zaru un tajā ievietoju elementu
                if(!current_branch[0].id){
                    current_branch=current_branch[0];
                }else{
                    current_branch[current_branch.length]={
                        parentNode:current_branch[0].parentNode,
                        parent:current_branch[0].parent
                    };
                    current_branch=current_branch[current_branch.length-1];
                }
                this.create_new_branch(current_branch,branch_id,DATA[i]);
            }else{
                break;
                throw "Nenormāls zaru izvietojums.";
            }
        }
        this.checkParentTree(MAP_CONTAINER.tree);
        expand.onclick=function(){YAHOO.example.DDApp.expand_collapse(MAP_CONTAINER.tree[0].tree,true,false);}
        collapse.onclick=function(){YAHOO.example.DDApp.expand_collapse(MAP_CONTAINER.tree[0].tree,false,false);}
    },
    create_new_branch: function(current_branch,branch_id,data){
        current_branch.path=current_branch.parentNode.path+branch_id+"_";
        //current_branch.id=container+"_container_"+branch_id;
        current_branch.visible=false;
        current_branch.id=branch_id;
        current_branch.params=data
        current_branch.deep=current_branch.parentNode.deep+1;
        //Izveidoju jaunu konteineri priekš menu ieraksta
        //Kontaineri aplieku zem parent, kas ir vecāka elementa koka elements
        //Pārējos elementus aplieku zem konteinera
        var new_container=document.createElement('div');
            new_container.className="menu_container";
            new_container.id=MAP_CONTAINER.container+"_container_"+branch_id
            new_container.style.paddingLeft=(MAP_CONTAINER.TAB_LENGTH*current_branch.deep)+"px";
          
        //Izveidoju jauno tools divu un jaunu content divu
            var new_content=document.createElement('div');
                new_content.className="menu_content";
                    text_node=this.add_text_node(new_content,branch_id,data);
                //TEXT
                current_branch.text=text_node;
                //Pievieno bultiņu (tukšu)
                current_branch.arrow=this.add_arrow(new_content);
            var new_tree=document.createElement('div');
                new_tree.className="menu_tree";
            new_container.appendChild(new_content);
            new_container.appendChild(new_tree);
        current_branch.parent.appendChild(new_container);
        
        //Beidzu veidot jauno tools divu un jauno content divu

        current_branch.container=new_container;
        current_branch.tree_element=new_tree;
        //Vienmēr izveidoju jaunajam zaram savu koku ar pirmo elementu, ar vienu atribūtu
        //vecāka elementu, kas norāda vecāku,(NAV DOM elements)
        current_branch.tree=[{
            parentNode:current_branch,
            parent:new_tree
        }];
        new_container.configuration=current_branch;
        //Gadījumā ja zars nav pirmajā līmenīt tad tiek pārbaudīti vecāki
       // if(current_branch.deep>1){
            
        //}
    },
    add_text_node:function(parent,id,data){
        var text_node=document.createElement('a');
        //text_node.target="blank";
        url="http://"+location.hostname+"/cms/"+data.controller+"/view/"+data.menuable_id;
        text_node.href=url
       // text_node.className="menu_content_text";
        text_node.innerHTML=data.title;   
        if(data.menuable_id>0){
            text_node.style.color=MAP_CONTAINER.color.ec
        }else{
            text_node.style.color=MAP_CONTAINER.color.ulc;
        } 
        parent.appendChild(text_node);
        //YAHOO.util.Event.addListener(text_node,"click",this.onTextClick,text_node,true);
        return text_node
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
    
    getTreeIds:function(tree){
        var arr=[];
        for(var i=0;i<tree.length;i++){
            var branch=tree[i];
            var parent_id=branch.parentNode.id
            arr[arr.length]=[branch.id,parent_id]
            if(branch.tree.length>1 || branch.tree[0].tools){
                arr=arr.concat(this.getTreeIds(branch.tree));
            }
        }
        return arr;
    },
    expand_collapse:function(tree,expand,deep){
        for(var i=0;i<tree.length;i++){
            var parent=tree[i];
           // if(deep && !expand && parent.deep<deep){return;}
            if(parent.tree.length>1 || parent.tree[0].tools){
                if(expand){
                    //Iespējams norādīt cik dziļi atvērt vai aizvērt koku 
                    if(!deep || (deep && expand && parent.deep<=deep)){
                        parent.arrow.childNodes[0].style.display="none";//="/images/arrow_orange_s.gif";
                        parent.arrow.childNodes[1].style.display="none";
                        parent.arrow.childNodes[2].style.display="block";
                        //parent.arrow.src="/images/arrow_orange_s.gif";
                        parent.visible=true;
                        parent.tree_element.style.display="block";
                    }
                }else{
                    if(!deep || (deep && parent.deep>deep)){
                        parent.arrow.childNodes[0].style.display="none";//="/images/arrow_orange_s.gif";
                        parent.arrow.childNodes[2].style.display="none";
                        parent.arrow.childNodes[1].style.display="block";
                        //parent.arrow.src="/images/arrow_orange_e.gif";
                        parent.visible=false;
                        parent.tree_element.style.display="none";
                    }
                }
                this.expand_collapse(parent.tree,expand,deep)
            }
        }
        return;
    },
    //Pārbauda visus koka elementu lai būtu pārliecināts, ka visiem kam ir bērni ir redzama bultiņa
    //bet visiem kam nav tiem nav redzama
    checkParentTree:function(tree){
       for(var i=0;i<tree.length;i++){
            if(tree[i].tree){
                tree[i].container.className="menu_container";
                //tree[i].sibling.className="menu_sibling";
                var parent=tree[i];
                if(parent.arrow && (parent.tree.length>1)){
                    if(parent.visible){
                        parent.arrow.childNodes[0].style.display="none";//="/images/arrow_orange_s.gif";
                        parent.arrow.childNodes[1].style.display="none";
                        parent.arrow.childNodes[2].style.display="block";
                        parent.tree_element.style.display="block";
                    }else{
                        parent.arrow.childNodes[0].style.display="none";//="/images/arrow_orange_s.gif";
                        parent.arrow.childNodes[2].style.display="none";
                        parent.arrow.childNodes[1].style.display="block";
                       // parent.arrow.src="/images/arrow_orange_e.gif";
                        parent.tree_element.style.display="none";
                    }
                }else{
                    if(parent.arrow){
                        parent.arrow.childNodes[1].style.display="none";//="/images/arrow_orange_s.gif";
                        parent.arrow.childNodes[2].style.display="none";
                        parent.arrow.childNodes[0].style.display="block";
                        parent.tree_element.style.display="none";
                    } 
                }
                this.checkParentTree(tree[i].tree)
            }else{
                return true;
            }
        }
    },
    //Pievienot zarama bultiņas 
    //Vienlaikus tiek ielasītas visas trīs bultiņas lai palielinātu ātrdarbību pēcāk
    add_arrow:function(element){
        var arrow=document.createElement('span');
            arrow.style.display="block";
            arrow.style.cssFloat="left";
            arrow.style.styleFloat="left";
            arrow.style.paddingTop="5px"
            var a_blank=document.createElement('img');
                a_blank.src="/images/cms/arrow_blank.gif";
                a_blank.style.display="block";
            var a_e=document.createElement('img');
                a_e.src="/images/cms/arrow_orange_e.gif";
                a_e.style.display="none";
            var a_s=document.createElement('img');
                a_s.src="/images/cms/arrow_orange_s.gif";
                a_s.style.display="none";
            arrow.appendChild(a_blank);
            arrow.appendChild(a_e);
            arrow.appendChild(a_s);
            arrow.onclick=function(e){
                var container=this.parentNode.parentNode;
                if(this.firstChild.style.display!="block"){
                    if(this.childNodes[1].style.display=="block"){
                        this.childNodes[1].style.display="none";
                        this.childNodes[2].style.display="block";
                        container.configuration.visible=true;
                        container.configuration.tree_element.style.display="block";
                    }else{
                        if(this.childNodes[2].style.display=="block"){
                            this.childNodes[2].style.display="none";
                            this.childNodes[1].style.display="block";
                            container.configuration.visible=false;
                            container.configuration.tree_element.style.display="none";
                        }  
                    }
                }
                
            };
       
        if(element.childNodes.length>0){
            var first_child=element.childNodes[0];
            element.insertBefore(arrow,first_child);
        }else{
            element.appendChild(arrow);
        }
        return arrow;
    },
    onTextClick:function(e){
        var data=this.parentNode.parentNode.configuration.params
        var url="/cms/"+data.controller+"/view/"+data.menuable_id;
        YAHOO.example.DDApp.insertAtCursor(elementById("myctext"), url);
        //alert(url);
    },
    insertAtCursor:function(myField, myValue) {
        //IE support
       // alert(1)
        if (document.selection) {
            myField.focus();
            sel = document.selection.createRange();
            sel.text = myValue;
        }
        //MOZILLA/NETSCAPE support
        else if (myField.selectionStart || myField.selectionStart == '0') {
            var startPos = myField.selectionStart;
            var endPos = myField.selectionEnd;
            myField.value = myField.value.substring(0, startPos)
            + myValue
            + myField.value.substring(endPos, myField.value.length);
        } else {
            myField.value += myValue;
        }
    }
    // calling the function
    
};
Event.onDOMReady(YAHOO.example.DDApp.init, YAHOO.example.DDApp, true);


}