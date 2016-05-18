var CohortsRouter = Backbone.Router.extend({
    routes: {
        "cohorts/new": "new",
        "cohorts": "index",
        "cohorts/:name(/)": "show"
    },
    new: function(){
        var cohort = new Cohort();
        var view = new NewCohortView({model: cohort});
    },
    show: function(name){
        var cohort = new Cohort({name: name});
        cohort.fetch({
            success: function(){
                var view = new CohortView({
                    model: cohort
                });
            }
        });
    },
    index: function(){
        var cohorts = new Cohorts();
        cohorts.fetch({
            success: function(){
                var view = new CohortsView({
                    collection: cohorts
                });
            }
        });
    }
});
