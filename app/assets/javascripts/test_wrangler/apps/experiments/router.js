var ExperimentsRouter = Backbone.Router.extend({
    routes: {
        "experiments/:name(/)": "show"
    },
    show: function(name){
        var experiment = new Experiment({name: name});
        experiment.fetch({
            success: function(){
                console.log(arguments);
                var view = new ExperimentView({
                    model: experiment
                });
            },
            error: function(){
                console.log(arguments);
            }
        })
    }
});
