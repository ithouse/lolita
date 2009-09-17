/*
 * Konfigurācijā tieks saņemts JSON masīvs
 * Attribūti
 *  options - tiek saņemts caur konstruktoru
 *      read_only(Boolean) - vai ir marķieris kustināms vai ir noklusētais marķieris redzams
 *      id_prefix(String) - konteinera id sākums, piemērs, id="my_map_134", id_prefix="my_map"
 *      icon(GIcon) - marķiera ikona
 *      unique_id - unikāls identifikātors obligāti jānorāda
 *      center_marker (bool) - nocentrē karti pārvietojot marķieri
 *      zoom (int) - level of magnification
 *  lat - noklusētais platums
 *  lng - noklusētais garums
 *  marker_count - skaitītājs no kura sāk marķieru skaitīšana, nav īpaša nozīme
 *
 */
LolitaGoogleMap=function(options){
    this.options=options
    this.marker_counter=0 //create index for each marker
    this.markers=[] //store all markers that are on map
    this.lat=56.9444123864; //coordinares of Rīga, Latvia
    this.lng=24.1009140015;
}
LolitaGoogleMap.prototype={
    /*
     *@@PUBLIC
     */
    init:function(){
        var that=this
        $(document).ready(function(){
            $("body").eq(0).unload(function(){
                GUnload()
            })
            that.load_map()
        })
    },
    /*
     *@@PRIVATE
     */
    load_map:function(){
        if (GBrowserIsCompatible()){// Do Map if Compatible Browser only
            this.map = new GMap2(elementById((this.options.id_prefix || "map")+"_"+this.options.unique_id));
            if(!this.options.read_only) this.map.enableScrollWheelZoom();
            this.add_controls() // add Gmap controls to map
            this.set_default_center()
            this.options.zoom=this.options.zoom || 15
            if(this.options.type=="multimedia"){ //need close tab if map in system side
                this.hide_current_tab()
            }
        }else{
            $("#map_"+this.options.unique_id).html("<div style='color: grey'>Error! Render Google Map</div>") ;
        }

    },
    /*
     *@@PRIVATE
     */
    set_default_center:function(){
        try{
            this.map.setCenter(new GLatLng(this.lat,this.lng),this.options.zoom);
            setTimeout(function(that){
                that.add_markers()
                if (that.options.center_marker && that.last_marker()){
                 that.change_center(that.last_marker(),true,this.options.zoom)
                }
            },1000,this)
        }catch(e){
            alert(e)
            setTimeout(function(that){
                that.set_default_center()
            },500,this)
        }
    },
    /*
     *@@PRIVATE
     *Default function that add given markers to map.
     *Add default marker if not read only map and is single marker map and no marker
     *is added yet
     */
    add_markers:function(){
        var icon=this.create_icon();
        for(var i=0;i<this.options.lat.length;i++){
            var lat=this.options.lat[i];
            var lng=this.options.lng[i];
            if(!((!lat || !lng) || (lat==0 || lng==0))){
                var point=new GLatLng(lat,lng);
                this.add_simple_marker(point,icon,{
                    lat:lat,
                    lng:lng
                })
            }
        }
        if(this.marker_counter==0 && !this.options.read_only && this.options.single){
            this.add_simple_marker(new GLatLng(this.lat,this.lng),icon,{})
        }
    },
    /*
     *@@PRIVATE
     *Add marker to map and creates related INPUT field
     *Params:
     *  point(GLatLng) - point where marke need to be
     *  icon(GIcon) - icon of marker
     *  values(JSON) - values that is set to <i>input</i> fields mostly (lat,lng, etc.)
     */
    add_simple_marker:function(start,icon,values){
        var marker=new GMarker(start,{
            icon:icon,
            draggable: !this.options.read_only
        });
        marker.counter=this.marker_counter
        this.map.addOverlay(marker);
        this.add_marker_events(marker)
        if(values) this.create_form_elements()
        this.markers.push(marker)
        this.marker_counter+=1
        return marker
    },
    /*@@PRIVATE
     * Create new INPUT elements with <i>hidden</i> type
     * Params:
     *  values(JSON) - contains default values for input fields
     * Return:
     *  void
     */
    create_form_elements:function(values){
        values=values || {}
        var $container=$("#object_map_"+this.options.unique_id+"_container")
        var fields=["lat","lng","description"]
        for(var i=0;i<fields.length;i++){
            var value=eval("values."+fields[i]+" ? values."+fields[i]+" : 0")
            $container.append('<input type="hidden" '+
                'name="map['+this.options.unique_id+']['+this.marker_counter+']['+fields[i]+']"'+
                'id="object_map_'+this.options.unique_id+'_'+fields[i]+'_'+this.marker_counter+'"'+
                'value="'+value+'"'
                )
        }
    },
    /*
     *@@PUBLIC
     *Add new marker to map if no single marker map or no marker added yet
     *This is used from outside to add marker
     */
    add_new_marker:function(lat,lng,icon){
        if(!this.options.single || this.markers.length<1){
            lat=lat || this.lat
            lng=lng || this.lng
            icon=icon || this.create_icon()
            return this.add_simple_marker(new GLatLng(lat,lng),icon,{})
        }else{
            return false
        }
    },
    add_marker_events:function(marker){
        var that=this;
        if (!this.options.read_only){
            GEvent.addListener(this.map, 'click', function(overlay, point){
                if (overlay){
                }else if (point){
                    if(that.last_marker()){
                        that.last_marker().setPoint(point)
                        that.current_zoom=this.getZoom();
                        that.change_center(that.last_marker())
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
    /*
     * @@PRIVATE
     * marker(GMarker) - must be specified
     * center(Boolean) - optional, center or not
     * zoom(Integer) - optional, map zoom to set
     */
    change_center:function(marker,center,zoom){
        var point=marker.getLatLng();
        if(this.options.center_marker || center) this.map.setCenter(point,zoom ||this.current_zoom);//map.getZoom()
        $('#object_map_'+this.options.unique_id+'_lat_'+marker.counter).attr("value",point.lat());
        $('#object_map_'+this.options.unique_id+'_lng_'+marker.counter).attr("value",point.lng());
    },
    last_marker:function(){
        return this.markers[this.markers.length-1]
    },
    /*
     * Seach for specific address, when found change last marker position to id
     * otherwise alert message that address canot be found
     */
    show_address:function(address){
        if (!this.map.geocoder)
            this.map.geocoder=new GClientGeocoder();
        var that=this
        this.map.geocoder.getLatLng(
            address,
            function(point){
                if (!point) {
                    alert(address + " not found!");
                } else{
                    if (typeof(that.last_marker())=="undefined"){
                        var icon=that.create_icon();
                        that.add_new_marker(point.lat,point.lng,icon)
                    }else{
                        that.last_marker().setPoint(point)
                    }
                    that.change_center(that.last_marker(),true)
                }
            }
            )
    },
    hide_current_tab:function(){
        if(!this.options.opened){
            $('#tab'+this.options.index+'container').css("display","none");
        }
        $("#map_form_"+this.options.unique_id).css("display","block")
    }
}