var Cohort = TestWranglerModel.extend({
    idAttribute: 'name',
    urlRoot: '/test_wrangler/api/cohorts',
    defaults: {
        state: 'inactive',
        criteria: [],
        experiments: []
    },
    parse: function(data){
        return data.cohort;
    },
    validate: function(attrs){
        var errors = [];
        this.validateState(attrs.state, errors);
        this.validateExperiments(attrs.experiments, errors);

        return errors.length > 0 ? errors : undefined;
    },
    validateState: function(state, errors){
        if(state === 'active' || state === 'inactive') return;
        errors.push(new Error("cohort state must be 'active' or 'inactive'"));
    },
    validateExperiments: function(experiments, errors){
        if(_.isArray(experiments)) return;
        errors.push(new Error("cohort experiments must be an array of experiment names"));
    },
    toJSON: function(options){
        if(this.attributes.newRecord){
            return {cohort: {name: this.id, priority: this.attributes.priority, criteria: this.attributes.variants}};
        } else {
            return {cohort: {experiments: this.attributes.experiments, state: this.attributes.state, priority: this.attributes.priority }};
        }
    }
});