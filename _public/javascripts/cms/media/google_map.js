/*
 * Konfigurācijā tieks saņemts JSON masīvs
 * Attribūti
 *  options - tiek saņemts caur konstruktoru
 *      read_only(Boolean) - vai ir marķieris kustināms vai ir noklusētais marķieris redzams
 *      id_prefix(String) - konteinera id sākums, piemērs, id="my_map_134", id_prefix="my_map"
 *      icon(GIcon) - marķiera ikona
 *      unique_id - unikāls identifikātors obligāti jānorāda
 *      center_marker - nocentrē karti pārvietojot marķieri
 *  lat - noklusētais platums
 *  lng - noklusētais garums
 *  marker_count - skaitītājs no kura sāk marķieru skaitīšana, nav īpaša nozīme
 *
 */
LolitaGoogleMap=function(options){
  this.options=options
  this.marker_counter=1
  this.lat=56.9444123864;
  this.lng=24.1009140015;
  this.last_marker=false;
//Rīgas koordinātas
}
LolitaGoogleMap.prototype={
  init:function(){
    var that=this
    $(document).ready(function(){
      $("body").eq(0).unload(function(){
        GUnload()
      })
      that.load_map()
    })
  },
  load_map:function(){
    if (GBrowserIsCompatible()){// Do Map if Compatible Browser only
      this.map = new GMap2(elementById((this.options.id_prefix || "map")+"_"+this.options.unique_id));
      this.map.enableScrollWheelZoom();
      this.add_controls() // add Gmap controls to map
      this.set_default_center()
      this.hide_current_tab()
    }else{
      $("#map_"+this.options.unique_id).html("<div style='color: grey'>Error! Render Google Map</div>") ;
    }

  },
  set_default_center:function(){
    try{
      this.map.setCenter(new GLatLng(this.lat,this.lng),15);
      this.add_markers()
    }catch(e){
      setTimeout(function(that){
        that.set_default_center()
      },500,this)
    }
  },
  add_markers:function(){
    var total_markers=0;
    var icon=this.create_icon();
    for(var i=0;i<this.options.lat.length;i++){
      var lat=this.options.lat[i];
      var lng=this.options.lng[i];
      if(!((!lat || !lng) || (lat==0 || lng==0))){
        total_markers++
        var point=new GLatLng(lat,lng);
        this.add_simple_marker(point,icon)
      }
    }
    if(total_markers==0 && !this.options.read_only){
      this.add_simple_marker(new GLatLng(this.lat,this.lng),icon)
    }
  },
  add_simple_marker:function(start,icon){
    var marker=new GMarker(start,{
      icon:icon,
      draggable: !this.options.read_only
    });
    marker.counter=this.marker_counter
    this.marker_counter+=1
    this.map.addOverlay(marker);
    this.add_marker_events(marker)
    this.last_marker=marker
  },
  add_marker_events:function(marker){
    var that=this;
    if (!this.options.read_only){
      GEvent.addListener(this.map, 'click', function(overlay, point){
        if (overlay){
        }else if (point){
          if(that.last_marker){
            that.last_marker.setPoint(point)
            that.current_zoom=this.getZoom();
            that.change_center(that.last_marker)
          }
        }
      });
    }

    if (!this.options.read_only){
      marker.enableDragging()
      GEvent.addListener(marker,'dragend',function() {
        that.current_zoom=that.map.getZoom();
        that.change_center(this)
      });
    //            GEvent.addListener(marker,'click',function(){
    //                this.openInfoWindowHtml("<b>asdf</b><span>Arturs</span>");
    //            })
    }
  },
  add_controls:function(){
    this.map.addControl(new GLargeMapControl());
    this.map.addControl(new GMapTypeControl());
    this.map.addControl(new GScaleControl()) ;
    this.map.addControl(new GOverviewMapControl()) ;
  },
    
  create_icon:function(){
    if(!this.options.icon){
      var icon = new GIcon();
      icon.image = "http://labs.google.com/ridefinder/images/mm_20_red.png";
      icon.shadow = "http://labs.google.com/ridefinder/images/mm_20_shadow.png";
      icon.iconSize = new GSize(12, 20);
      icon.shadowSize = new GSize(22, 20);
      icon.iconAnchor = new GPoint(6, 20);
      return icon
    }else{
      return this.options.icon
    }
  },
  change_center:function(marker){
    var point=marker.getLatLng();
    if(this.options.center_marker) this.map.setCenter(point,this.current_zoom);//map.getZoom()
    $('#object_map_'+this.options.unique_id+'_lat_'+marker.counter).attr("value",point.lat());
    $('#object_map_'+this.options.unique_id+'_lng_'+marker.counter).attr("value",point.lng());
  },
  hide_current_tab:function(){
    $('#tab'+this.options.index+'container').css("display","none");
  }
}

function show_address(map,address){
  if (!map.geocoder)
    map.geocoder=new GClientGeocoder();
  map.geocoder.getLatLng(
    address,
    function(point)
    {
      if (!point) {
        alert(address + " not found");
      } else
      {
        if (typeof(map.last_marker)=="undefined")
        {
          var icon=map.create_icon();
          map.add_simple_marker(point,icon)
        }
        map.last_marker.setPoint(point)
        map.change_center(map.last_marker)
        map.map.setCenter(point,map.map.getZoom());
      }
    })
}