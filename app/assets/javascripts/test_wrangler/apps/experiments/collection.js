var Experiments = Backbone.Collection.extend({
    model: Experiment,
    url: '/test_wrangler/api/experiments',
    parse: function(data){
        return data.experiments;
    }
});