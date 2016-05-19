var NewCohortView = TestWranglerView.extend({
    tagName: 'main',
    className: 'cohort new',
    templates: {form: 'cohorts/form'},
    events: {
        "click button.add-criterion": "addCriterion",
        "click button.remove-criterion": "removeCriterion",
        "click button.save": "saveCohort",
        "change input.cohort-name": "updateCohortName",
        "change input.cohort-priority": "updateCohortPriority"
    },
    ready: function(){
        this.render(true);
        this.listenTo(this.model, 'change', this.render);
    },
    render: function(firstRender){
        this.$el.html(this.templates['form'](_.clone(this.model.attributes)));
        if(firstRender) $('body').append(this.$el);
        return this;
    },
    addCriterion: function(e){
        var type = $('.new-criterion-type').val();
        var universal = type === 'universal';
        var criterion = {type: type};

        if(!universal){
            var json = $('.new-criterion-rules').val();
            try{
                json = JSON.parse(json);
            } catch(e){
                this.handleError(null, "JSON improperly formatted. JSON error:`" + e.message + "'");
                return;
            }
            criterion[type] = json;
        }
        var criteria = _.clone(this.model.get("criteria"));
        criteria.push(criterion);
        this.model.set({criteria: criteria});
    },
    removeCriterion: function(e){
        var index = $(e.target).data('index');
        var criteria = _.clone(this.model.get('criteria'));
        critera.splice(index, 1);
        this.model.set({criteria: criteria});
    },
    updateCohortName: function(e){
        this.model.set('name', $(e.target).val());
    },
    updateCohortPriority: function(e){
        this.model.set('priority', +$(e.target).val());
    },
    saveCohort: function(e){
        e.preventDefault();
        var self = this;
        this.model.save(null, {
            method: 'create',
            url: '/test_wrangler/api/cohorts',
            success: function(){
                Backbone.history.trigger('beforePageChange');
                Backbone.history.navigate("/cohorts/" + self.model.attributes.name, {trigger: true});
            },
            error: function(model, response){
                self.handleError(response.status);
            }
        });
    },
    handleError: function(status, message){
        var message;

        switch(status){
            case 409:
                message = "Cohort name is already taken"
                break;
            case 422:
                message = "Your cohort must have a name and at least one criterion"
                break;
            default:
                message = message || "An error occured on the server, check your data and try again"
                break;
        }

        this.$el.prepend($("<strong id=\"errors\">Error: " + message + "</strong>"));
    }
});