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
 * @headsTip: Examples and documentation at: http://thecodecentral.com/2008/11/12/ctrotator-a-flexible-itemimage-rotator-script-for-jquery
 */

function ctRotatorBridgeRss20(url, readyCallback){
 
  this.url = url;
  this.readyCallback = readyCallback;
}

ctRotatorBridgeRss20.prototype = {
  getDataSource:function(){
   var readyCallback = this.readyCallback;
   var dataSource = [];
   $.get(this.url, {}, function(data){
     $(data).find('channel item').each(function(){
	   var e = $(this);
	   dataSource.push({
	     title:e.find('title').text(),
		 url: e.find('link').text(),
		 tip: e.find('description').text()
	   });
	 });
	 readyCallback(dataSource);
   }, 'xml');
   
   return dataSource;
  }
  
};
