/**
 * @author arturs
 */

if (typeof ITH == "undefined"){
	ITH={};
}
ITH.namespace = function() {
    var a=arguments, o=null, i, j, d;
    for (i=0; i<a.length; ++i) {
        d=a[i].split(".");
        o=ITH;
        // ITHouse is implied, so it is ignored if it is included
        for (j=(d[0] == "ITH") ? 1 : 0; j<d.length; ++j) {
            o[d[j]]=o[d[j]] || {};
            o=o[d[j]];
        }
    }
    return o;
};
ITH.extend = function(subc, superc, overrides) {
    var F = function() {};
    F.prototype=superc.prototype;
    subc.prototype=new F();
    subc.prototype.constructor=subc;
    subc.superclass=superc.prototype;
    if (superc.prototype.constructor == Object.prototype.constructor) {
        superc.prototype.constructor=superc;
    }

    if (overrides) {
        for (var i in overrides) {
            subc.prototype[i]=overrides[i];
        }
    }
};

ITH.namespace("Cms","Media","ImageFile","ImageFileVersions","Event","Tree","Menu","Branch","MenuTree","MenuBranch","Elements");
