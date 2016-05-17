var TestWranglerView = Backbone.View.extend({
    initialize: function(){
        this.promise = this.setTemplates()
                        .then(this.ready.bind(this));
    },
    setTemplates: function(){
        var self = this;
        return $.when.apply($.when, _.keys(this.templates).map(function(key){
            return TemplateCache.get(self.templates[key])
                    .then(function(template){
                        self.templates[key] = template;
                    });
        }));
    }
});