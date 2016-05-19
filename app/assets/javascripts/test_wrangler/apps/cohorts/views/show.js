var CohortView = TestWranglerView.extend({
    tagName: 'main',
    className: 'cohort show',
    events: {
        "click button.delete": "destroyModel",
        "click .other-experiments button.toggle-experiment": "addExperiment",
        "click .experiments button.toggle-experiment": "removeExperiment",
        "click button.activate": "activateCohort",
        "click button.deactivate": "deactivateCohort",
        "click button.set-priority": "setPriority"
    },
    templates: {show: 'cohorts/show'},
    ready: function(){
        var self = this;
        this.listenTo(this.model, 'sync', this.render.bind(this));
        return $.getJSON('/test_wrangler/api/experiments')
            .then(function(data){
                self.allExperiments = data.experiments.map(function(e){return e.name;});
                self.unusedExperiments = _.difference(self.allExperiments, self.model.get('experiments'));
                self.render(true);
            });
    },
    render: function(firstRender){
        var data = _.extend({}, _.clone(this.model.attributes), {otherExperiments: this.unusedExperiments})
        this.$el.html(this.templates['show'](data));
        if(firstRender) $('body').append(this.$el);
        return this;
    },
    addExperiment: function(e){
        var experimentName = $(e.target).parent('label').data('experimentName');
        var experiments = _.clone(this.model.get('experiments'));

        experiments.push(experimentName);
        this.unusedExperiments.splice(this.unusedExperiments.indexOf(experimentName), 1);
        this.model.save({experiments: experiments});
    },
    removeExperiment: function(e){
        var experimentName = $(e.target).parent('label').data('experimentName');
        var experiments = _.clone(this.model.get('experiments'));
        
        experiments.splice(experiments.indexOf(experimentName), 1);
        this.unusedExperiments.push(experimentName);
        this.model.save({experiments: experiments});
    },
    activateCohort: function(){
        this.model.save({state: 'active'});
    },
    deactivateCohort: function(){
        this.model.save({state: 'inactive'})
    },
    destroyModel: function(){
        this.model.destroy({success: function(){
            Backbone.history.trigger('beforePageChange');
            Backbone.history.navigate('cohorts', true);
        }});
    },
    setPriority: function(e){
        var priority = $('input.cohort-priority').val();
        this.model.save({priority: priority})
    }
});