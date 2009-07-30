/*
 * jQuery ctRotator Plugin
 * Examples and documentation at:http://thecodecentral.com/2008/11/12/ctrotator-a-flexible-itemimage-rotator-script-for-jquery
 * Under MIT license http://www.opensource.org/licenses/mit-license.php
 *
 * @author: Cuong Tham
 * @version: 1.0
 * @requires jQuery v1.2.6 or later
 *
 * @headsTip: Customizable rotating script for displaying large quantity of items in an interesting way
 */

(function($) {
    $.fn.ctRotator = function(dataSource, options){
        options = $.extend({
            showCount: 5,
            speed: 6000, //in milliseconds
            fadeInSpeed: 0,
            fadeOutSpeed: 0,
            fadeEffect: true,
            useTooltip: false,
            shuffle: false,
            itemRenderer: function(item){
                if(item){
                    if(item.url == null){
                        return '<li class="ctrotator-item">' + item.title + '</li>';
                    }else{
                        return '<li class="ctrotator-item"><a href="' + item.url+ '">' + item.title + '</a></li>';
                    }
                }else{
                    return '<li class="ctrotator-item"></li>'
                }
            },
            tooltipOptions: {}
        }, options);
  
        if(options.showCount < 1){
            throw('options.showCount must be greater than 0');
        }
  
        return this.each(function(){
            $(this).empty();
            doRotating(dataSource, this, options);
        });
    };

    function doRotating(dataSource, container, options){
        var rotator = new ctRotatorList(dataSource, options.shuffle);
        var showCount = options.showCount;
        for(var i = 0; i < showCount; i++){
            insertItem(rotator.gotoNext(), container, options);
        }
        updateRotation(rotator, container, options);
    }

    function updateRotation(rotator, container, options){
        var item = rotator.gotoNext();
        var newLi = insertItem(item, container, options);
  
        if(options.fadeEffect){
            newLi.hide();
            var inSpeed = options.fadeInSpeed;
            var outSpeed = options.fadeOutSpeed;
            $(container).children(':last').fadeOut(outSpeed, function(){
                $(this).remove()
                newLi.fadeIn(inSpeed, function(){
                    setTimeout(function(){
                        updateRotation(rotator, container, options)
                        }, options.speed);
                });
            });
        }else{
            $(container).children(':last').remove();
            setTimeout(function(){
                updateRotation(rotator, container, options)
                }, options.speed);
        }
  
    }

    function insertItem(item, container, options){
        var rendered = options.itemRenderer(item);
        var newLi = $(rendered);
        if(newLi.size() == 0){
            newLi = $('<li></li>').append(rendered);
        }
        $(container).prepend(newLi);
   
        if(options.useTooltip){
            newLi.tooltip($.extend({
                fade:50,
                delay:800,
                opacity: 1,
                bodyHandler: function(){
                    return item.tip;
                }
            }, options.tooltipOptions));
        }
   
        return newLi;
    }


    function ctRotatorList(list, shuffle){
        this.cursor = 0;
        this.list = list;
        this.shuffle = shuffle == null ? false : shuffle;
        if(this.shuffle){
            this.list = this.shuffleArray(this.list);
        }
    }

    ctRotatorList.prototype = {
        gotoNext:function(){
            if(this.cursor >= this.getCount() - 1){
                this.cursor = 0;
            }else{
                this.cursor++;
            }
            return this.list[this.cursor];
        },
        getCount:function(){
            return this.list.length;
        },
        shuffleArray:function(o){ //credit http://snippets.dzone.com/posts/show/849
            for(var j, x, i = o.length; i; j = parseInt(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
            return o;
        }
    };

})(jQuery); 