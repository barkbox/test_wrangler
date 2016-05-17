var ExperimentsRouter = Backbone.Router.extend({
    routes: {
        "experiments/new": "new",
        "experiments": "index",
        "experiments/:name(/)": "show"
    },
    new: function(){
        var experiment = new Experiment();
        var view = new NewExperimentView({model: experiment});
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
