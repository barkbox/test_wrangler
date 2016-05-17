var Experiments = Backbone.Collection.extend({
    model: Experiment,
    url: '/test_wrangler/api/experiments',
    parse: function(data){
        return data.experiments.map(function(exp){ return {experiment: exp}});
    }
});