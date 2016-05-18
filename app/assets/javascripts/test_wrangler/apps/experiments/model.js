var Experiment = TestWranglerModel.extend({
    idAttribute: 'name',
    urlRoot: '/test_wrangler/api/experiments',
    defaults: {
        state: 'inactive',
        variants: [],
        cohorts: []
    },
    parse: function(data){
        return data.experiment;
    },
    validate: function(attrs){
        var errors = [];
        this.validateState(attrs.state, errors);
        this.validateCohorts(attrs.cohorts, errors);

        return errors.length > 0 ? errors : undefined;
    },
    validateState: function(state, errors){
        if(state === 'active' || state === 'inactive') return;
        errors.push(new Error("experiment state must be 'active' or 'inactive'"));
    },
    validateCohorts: function(cohorts, errors){
        if(_.isArray(cohorts)) return;
        errors.push(new Error("experiment cohorts must be an array of cohort names"));
    },
    toJSON: function(options){
        if(this.attributes.newRecord){
            return {experiment: {name: this.id, variants: this.attributes.variants}};
        } else {
            return {experiment: {cohorts: this.attributes.cohorts, state: this.attributes.state}};
        }
    }
});