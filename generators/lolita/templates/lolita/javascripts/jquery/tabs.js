function Tabs(container_id,body_id, options){
    options = $.extend({
        showCount: 5,
        speed: 500, //in milliseconds
        fadeInSpeed: 750,
        fadeOutSpeed: 250,
        fadeEffect: true,
        tooltipOptions: {}
    }, options);
    this.createTabs($(container_id),body_id,options);
}
Tabs.prototype={
    createTabs:function(container,body_id,options){
        var tabs=this.getTabs(body_id);
        container.find("a").each(function(i){
            $(this).data("tab",tabs[i])
            $(this).data("body",body_id)
            $(this).click(function(event){
                $(this).siblings(".cur-tab").each(function(){
                    $(this).removeClass("cur-tab")
                    $(this).addClass("tab")
                })
                $($(this).data("body")).children("div").each(function(){
                    $(this).hide();
                })
                $(this).data("tab").fadeIn("normal");
                $(this).addClass("cur-tab")
                event.preventDefault();
            });
        });
    },

    getTabs:function(body_id){
        var tabs=[]
        $(body_id).children('div').each(function(){
            tabs.push($(this))
        })
        return tabs
    }

}