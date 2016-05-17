var ExperimentsRouter = Backbone.Router.extend({
    routes: {
        "experiments/:name(/)": "show",
        "experiments": "index"
    },
    show: function(name){
        var experiment = new Experiment({name: name});
        experiment.fetch({
            success: function(){
                var view = new ExperimentView({
                    model: experiment
                });
            }
        });
    },
    index: function(){
        var experiments = new Experiments();
        experiments.fetch({
            success: function(){
                var view = new ExperimentsView({
                    collection: experiments
                })
            }
        });
    }
});
