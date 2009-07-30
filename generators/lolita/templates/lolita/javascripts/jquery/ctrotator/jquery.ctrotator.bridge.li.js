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

function ctRotatorBridgeLi(container){
  this.container = container;
}

ctRotatorBridgeLi.prototype = {
  getDataSource:function(){
    var dataSource = [];
    this.container.find('li').each(function(){
	  var e = $(this);
	  if(e.children('a').size() == 0){
	    dataSource.push({title:e.text()});
	  }else{
	    e = e.children('a');
	    dataSource.push({title:e.html(), url:e.attr('href')});
	  }
	});
	return dataSource;
  }
};
