try{
    if(!FlashLoaderPlayers){FlashLoaderPlayers=[]}
}catch(error){
    FlashLoaderPlayers=[]
}
FlashLoader=function(){
    return{
        create:function(id,base_options,flash_vars,flash_options){
            FlashLoaderPlayers.push([id,{
                base:base_options,
                flash_v:flash_vars,
                flash_o:flash_options
            }])
            FlashLoader.domLoad(id)
            return true
        },
        load:function(id){
            var player=false
            for(var i in FlashLoaderPlayers){
                if(FlashLoaderPlayers[i][0]==id){
                    player=FlashLoaderPlayers[i][1]
                    if(player){
                        var so=new SWFObject(player.base.player,player.base.type,player.base.width,player.base.height,player.base.version);
                        so.addParam('flashvars',player.flash_v);
                        for(var key in player.flash_o){
                            so.addParam(key,player.flash_o[key])
                        }
                        so.write(id);
                    }
                    delete FlashLoaderPlayers[i]
                }
            }
            
        },
        //Rewrited from UFO
        /*	Unobtrusive Flash Objects (UFO) v3.20 <http://www.bobbyvandersluis.com/ufo/>
            Copyright 2005, 2006 Bobby van der Sluis
            This software is licensed under the CC-GNU LGPL <http://creativecommons.org/licenses/LGPL/2.1/>
        */
        domLoad: function(id) {
            var _t = setInterval(function() {
                if ((document.getElementsByTagName("body")[0] != null || document.body != null) && document.getElementById(id) != null) {
                    FlashLoader.load(id);
                    clearInterval(_t);
                }
            }, 250);
            if (typeof document.addEventListener != "undefined") {
                document.addEventListener("DOMContentLoaded", function() {
                    FlashLoader.load(id); clearInterval(_t);
                } , null); // Gecko, Opera 9+
            }
        }
    }
}()