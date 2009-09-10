LolitaGoogleMap=function(options){
    this.options=options
}
LolitaGoogleMap.prototype={
    load:function(){
        var lat=this.options.lat || 0;
        var lng=this.options.lng || 0;
        if ((!lat || !lng)||(lat==0 || lng==0)){
            lat=56.9444123864;
            lng=24.1009140015;
        //Rīgas koordinātas
        }
        alert(112343)
        if (GBrowserIsCompatible()){// Do Map if Compatible Browser only
            alert(elementById("map_"+this.options.id))
            this.map = new GMap2(elementById("map_"+this.options.id));
            //}
            this.map.enableScrollWheelZoom();
            this.map.addControl(new GLargeMapControl());
            this.map.addControl(new GMapTypeControl());
            this.map.addControl(new GScaleControl()) ;
            this.map.addControl(new GOverviewMapControl()) ;

            var icon = new GIcon();
            icon.image = "http://labs.google.com/ridefinder/images/mm_20_red.png";
            icon.shadow = "http://labs.google.com/ridefinder/images/mm_20_shadow.png";
            icon.iconSize = new GSize(12, 20);
            icon.shadowSize = new GSize(22, 20);
            icon.iconAnchor = new GPoint(6, 20);


            // alert(lat,lng);
            // alert(icon.iconSize);

            var start = new GLatLng(lat, lng);//new GLatLng(56.945348705799276, 24.100570678710938) ; // Rīga
            try{
                this.map.setCenter(start,11);
            }catch(e){}
            // alert(start);
            this.marker=new GMarker(start,{
                icon:icon,
                draggable: !this.options.read_only
                });
            this.map.addOverlay(this.marker);
            //  alert(marker);
            if (!this.options.read_only){
                GEvent.addListener(this.map, 'click', function(overlay, point){
                    if (overlay){
                    }else if (point){
                        this.marker.setPoint(point)
                        this.current_zoom=this.map.getZoom();
                        changecenter()
                    }
                });
            }

            if (!this.options.read_only){
                this.marker.enableDragging()
                GEvent.addListener(this.marker,'dragend',function() {
                    changecenter()
                    });
            }
            $('#tab'+this.options.tab+'container').css("display","none");
        }else{
            $("#map_"+this.options.id).html("<div style='color: grey'>Error! Render Google Map</div>") ;
        }

    },
    changecenter:function(){
        this.map.setCenter(this.marker.getPoint(),this.current_zoom);//map.getZoom()
        this.point=this.marker.getLatLng();
        $('#object_map_lat').val(this.point.lat());
        $('#object_map_lng').val(this.point.lng());
    },
    changelocation:function(lat,lng){
        this.point=new GLatLng(lat, lng);
        alert(lat)


        this.marker.setPoint(this.point);
        changecenter();
    },
    getposition:function(){
        return this.marker.getLatLng();
    }
}
