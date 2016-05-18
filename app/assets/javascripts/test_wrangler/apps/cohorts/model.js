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
        this.validateCohorts(attrs.cohorts, errors);

        return errors.length > 0 ? errors : undefined;
    },
    validateState: function(state, errors){
        if(state === 'active' || state === 'inactive') return;
        errors.push(new Error("cohort state must be 'active' or 'inactive'"));
    },
    validateCohorts: function(cohorts, errors){
        if(_.isArray(cohorts)) return;
        errors.push(new Error("cohort cohorts must be an array of cohort names"));
    },
    toJSON: function(options){
        if(this.isNew){
            return {cohort: {name: this.id, variants: this.attributes.variants}};
        } else {
            return {cohort: {cohorts: this.attributes.cohorts, state: this.attributes.state}};
        }
    }
});