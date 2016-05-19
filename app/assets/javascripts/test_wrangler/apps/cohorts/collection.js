var Cohorts = Backbone.Collection.extend({
    model: Cohort,
    url: '/test_wrangler/api/cohorts',
    parse: function(data){
        return data.cohorts.map(function(coh){ return {cohort: coh}});
    }
});