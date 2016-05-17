var TemplateCache = (function(){
    var cache = {};
    return {
        get: function(name){
            if(cache[name]) return $.Deferred().resolve(cache[name]);
            return $.get('/assets/test_wrangler/' + name + '.dot')
                        .then(function(file){
                            cache[name] = doT.template(file);
                            return cache[name];
                        });
        }
    }
}());