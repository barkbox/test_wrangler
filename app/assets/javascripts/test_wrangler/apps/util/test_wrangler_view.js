var TestWranglerView = Backbone.View.extend({
    initialize: function(){
        var self = this;
        this.promise = this.setTemplates()
                        .then(function(){
                            self.listenToOnce(Backbone.history, 'route', self.remove.bind(self));
                        })
                        .then(this.ready.bind(this));
    },
    setTemplates: function(){
        var self = this;
        return $.when.apply($.when, _.keys(this.templates).map(function(key){
            if(_.isFunction(self.templates[key])) return $.Deferred().resolve();
            return TemplateCache.get(self.templates[key])
                    .then(function(template){
                        self.templates[key] = template;
                    });
        }));
    }
});