// IE11 has an incomplete implementation of Set which doesn't allow you to iterate the keys
// so this code assumes you want a full implementation and will redefine Set if the half
// implementation is present
if (typeof Set === "undefined" || typeof Set.prototype.keys !== "function") {
    var Set = (function() {
        "use strict";
        
        var iterables = {
            "[object Array]": true,
            "[object Arguments]": true,
            "[object HTMLCollection]": true,
            "[object NodeList]": true
        };
        
        // shortcuts
        var hasOwn = Object.prototype.hasOwnProperty;
        var toString = Object.prototype.toString;
        
        function hasOwnProp(obj, prop) {
            return hasOwn.call(obj, prop);
        }
        
        function isIterable(item) {
            // for purposes of this implementation, an iterable is anything we can iterate with
            // a classic for loop:
            //     for (var i = 0; i < item.length; i++)
            // Currently accepts: array, arguments object, HTMLCollection, NodeList
            // and anything that has a .length with a numeric value and, if .length > 0, the first item has a nodeType property
            var name;
            if (typeof item === "object") {
                name = toString.call(item);
                return ((iterables[name] === true) || 
                    (typeof item.length === "number" && 
                        item.length >= 0 && 
                        (item.length === 0 || (typeof item[0] === "object" && item[0].nodeType > 0))
                    )
                );
            }
            return false;
        }

        // decide if we can use Object.defineProperty
        // include a test for Object.defineProperties (which IE8 does not have) to eliminate
        // using the broken Object.defineProperty in IE8
        var canDefineProperty = Object.defineProperty && Object.defineProperties;
        
        function setProperty(obj, propName, value, enumerable, writable) {
            if (canDefineProperty) {
                Object.defineProperty(obj, propName, {
                    enumerable: enumerable,
                    configurable: false,
                    writable: writable,
                    value: value
                });
            } else {
                obj[propName] = value;
            }
        }
        
        // this private function is used like a private method for setting
        // the .size property.  It cannot be called from outside this closure.
        var settable = false;
        function setSize(obj, val) {
            settable = true;
            obj.size = val;
            settable = false;
        }

        // this is the constructor function which will be returned
        // from this closure
        function SetConstructor(arg) {
            // private member variable, not used if IE8
            var size = 0;
            
            // set properties in cross-browser way
            setProperty(this, "baseType", "Set", false, false);   // not enumerable, not writeable
            setProperty(this, "_data", {}, false, true);          // not enumerable, writeable
            if (canDefineProperty) {
                Object.defineProperty(this, "size", {
                    enumerable: true,
                    configurable: false,
                    get: function() { return size;},
                    set: function(val) {
                        if (!settable) {throw new Error("Can't set size property on Set object.")}
                        size = val;
                    }
                });
            } else {
                // .size is just regular property in IE8
                this.size = 0;
            }
            // now add initial data
            // per spec make sure it isn't undefined or null
            if (arg !== undefined && arg !== null) {
                if (isIterable(arg)) {
                    for (var i = 0; i < arg.length; i++) {
                        this.add(arg[i]);
                    }
                // also check our own custom property in case
                // there is cross window code that won't pass instanceof
                } else if (arg instanceof Set || arg.baseType === "Set") {
                    arg.forEach(function(item) {
                        this.add(item);
                    }, this);
                }
            }
        }

        // state variables and shared constants
        var objectCntr = 0;
        var objectCntrBase = "obj_";
        var objectCntrProp = "__objectPolyFillID";
        
        // types where we just use the first 3 letters of the type
        // plus underscore + toString() to make the key
        // The first 3 letters of the type makes a namespace for each
        // type so we can have things like 0 and "0" as separate keys
        // "num_0" and "str_0".
        var autoTypes = {
            "string": true,
            "boolean": true,
            "number": true,
            "undefined": true
        };
        
        function getKey(val, putKeyOnObject) {
            // manufacture a namespaced key
            var type = typeof val, id;
            if (autoTypes[type]) {
                return type.substr(0, 3) + "_" + val;
            } else if (val === null) {
                return "nul_null";
            } else if (type === "object" || type === "function") {
                // coin a unique id for each object and store it on the object
                if (val[objectCntrProp]) {
                    return val[objectCntrProp];
                } else if (!putKeyOnObject) {
                    // it only returns null if there is no key already on the object
                    // and it wasn't requested to create a new key on the object
                    return null;
                } else {
                    // coin a unique id for the object
                    id = objectCntrBase + objectCntr++;
                    // include a test for Object.defineProperties to rule out IE8 
                    // which can't use Object.defineProperty on normal JS objects
                    if (toString.call(val) === "[object Object]" && canDefineProperty) {
                        Object.defineProperty(val, objectCntrProp, {
                            enumerable: false,
                            configurable: false,
                            writable: false,
                            value: id
                        });
                    } else {
                        // no Object.defineProperty() or not plain object, so just assign property directly
                        val[objectCntrProp] = id;
                    }
                    return id;
                }
            } else {
                throw new Error("Unsupported type for Set.add()");
            }
        }
        
        function SetIterator(keys, data, format) {
            var index = 0, len = keys.length;
            this.next = function() {
                var val, result = {}, key;
                while (true) {
                    if (index < len) {
                        result.done = false;
                        key = keys[index++];
                        val = data[key];
                        // check to see if key might have been removed
                        // undefined is a valid value in the set so we have to check more than that
                        // if it is no longer in the set, get the next key
                        if (val === undefined && !hasOwnProp(data, key)) {
                            continue;
                        }
                        if (format === "keys") {
                            result.value = val;
                        } else if (format === "entries") {
                            result.value = [val, val];
                        }
                    } else {
                        // clear references to outside data
                        keys = null;
                        data = null;
                        result.done = true;
                    }
                    return result;
                }
            };
        }
        
        function getKeys(data) {
            var keys = [];
            for (var prop in data) {
                if (hasOwnProp(data, prop)) {
                    keys.push(prop);
                }
            }
            return keys;
        }
        
        SetConstructor.prototype = {
            add: function(val) {
                var key = getKey(val, true);
                if (!hasOwnProp(this._data, key)) {
                    this._data[key] = val;
                    setSize(this, this.size + 1);
                }
                return this;
            },
            clear: function() {
                this._data = {};
                setSize(this, 0);
            },
            // delete has to be in quotes for IE8 - go figure
            "delete": function(val) {
                var key = getKey(val, false);
                if (key !== null && hasOwnProp(this._data, key)) {
                    delete this._data[key];
                    setSize(this, this.size - 1);
                    return true;
                }
                return false;
            },
            // .remove() is non-standard, but here for anyone who wants to use it
            // so that you can use this polyfill all the way down to IE7 and IE8
            // since IE8 can't use a method named .delete()
            remove: function(val) {
                return this["delete"](val);
            },
            forEach: function(fn /*, context */) {
                // by spec, we have to type check the fn argument
                if (typeof fn !== "function") return;
                
                // context argument is optional, but .forEach.length is supposed to be 1 by spec
                // so we declare it this way
                var context = arguments[1];
                
                // forEach specifies that the iteration set is
                // determined before the first callback so we get all the
                // keys first
                var iter = this.keys(), next, item;
                while ((next = iter.next()) && !next.done) {
                    item = next.value;
                    fn.call(context, item, item, this);
                }
            },
            has: function(val) {
                var key = getKey(val, false);
                if (key === null) return false;
                return hasOwn.call(this._data, key);
            },
            values: function() {
                return this.keys();
            },
            keys: function() {
                return new SetIterator(getKeys(this._data), this._data, "keys");
            },
            entries: function() {
                return new SetIterator(getKeys(this._data), this._data, "entries");
            }
        };
            
        SetConstructor.prototype.constructor = SetConstructor;    
        
        return SetConstructor;
    })();
}