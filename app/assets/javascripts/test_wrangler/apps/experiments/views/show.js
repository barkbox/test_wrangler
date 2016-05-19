var ExperimentView = TestWranglerView.extend({
    tagName: 'main',
    className: 'experiment show',
    events: {
        "click button.delete": "destroyModel",
        "click .other-cohorts button.toggle-cohort": "addCohort",
        "click .cohorts button.toggle-cohort": "removeCohort",
        "click button.activate": "activateExperiment",
        "click button.deactivate": "deactivateExperiment"
    },
    templates: {show: 'experiments/show'},
    ready: function(){
        var self = this;
        self.listenTo(self.model, 'sync', self.render.bind(self));
        return $.getJSON('/test_wrangler/api/cohorts')
            .then(function(data){
                self.allCohorts = data.cohorts.map(function(c){return c.name;});
                self.unusedCohorts = _.difference(self.allCohorts, self.model.get('cohorts'));
                self.render(true);
            });
    },
    render: function(firstRender){
        var data = _.extend({}, _.clone(this.model.attributes), {otherCohorts: this.unusedCohorts})
        this.$el.html(this.templates['show'](data));
        if(firstRender) $('body').append(this.$el);
        return this;
    },
    addCohort: function(e){
        var cohortName = $(e.target).parent('label').data('cohortName');
        var cohorts = _.clone(this.model.get('cohorts'));

        cohorts.push(cohortName);
        this.unusedCohorts.splice(this.unusedCohorts.indexOf(cohortName), 1);
        this.model.save({cohorts: cohorts});
    },
    removeCohort: function(e){
        var cohortName = $(e.target).parent('label').data('cohortName');
        var cohorts = _.clone(this.model.get('cohorts'));
        
        cohorts.splice(cohorts.indexOf(cohortName), 1);
        this.unusedCohorts.push(cohortName);
        this.model.save({cohorts: cohorts});
    },
    activateExperiment: function(){
        this.model.save({state: 'active'});
    },
    deactivateExperiment: function(){
        this.model.save({state: 'inactive'})
    },
    destroyModel: function(){
        this.model.destroy({success: function(){
            Backbone.history.trigger('beforePageChange');
            Backbone.history.navigate('experiments', true);
        }});
    }
});