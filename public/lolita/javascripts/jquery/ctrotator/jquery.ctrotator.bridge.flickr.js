/*
 * jQuery ctRotator Plugin briget
 * Convert an ul or ol list to a useable data source for ctRotator
 * 
 * Under MIT license http://www.opensource.org/licenses/mit-license.php
 *
 * @author: Cuong Tham
 * @version: 1.0
 * @requires jQuery v1.2.6 or later
 * @requires ctRotator
 *
 * @headsTip: Examples and documentation at:http://thecodecentral.com/2008/11/12/ctrotator-a-flexible-itemimage-rotator-script-for-jquery
 */

function ctRotatorBridgeFlickr(url, readyCallback){
  this.url = url;
  this.readyCallback = readyCallback;
}

ctRotatorBridgeFlickr.prototype = {
  getDataSource:function(){
    var readyCallback = this.readyCallback;
    var dataSource = [];    
	$.get(this.url, {}, function(data){
       for(var i in data.items){
	     var e = data.items[i];
	     dataSource.push({title: e.title, tip: e.description, image: e.media.m, url: e.link});
	   }
	   readyCallback(dataSource);
     }, 'jsonp');
   return dataSource;
  }
};
