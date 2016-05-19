var NewExperimentView = TestWranglerView.extend({
    tagName: 'main',
    className: 'experiment new',
    templates: {form: 'experiments/form'},
    events: {
        "click button.add-variant": "addVariant",
        "click button.remove-variant": "removeVariant",
        "click button.save": "saveExperiment",
        "change input.experiment-name": "updateExperimentName",
        "change input.variant-name": "updateVariantName",
        "change input.variant-weight": "updateVariantWeight"
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
    addVariant: function(e){
        var name = $('.new-variant-name').val();
        var weight = +$('.new-variant-weight').val();
        var variants = _.clone(this.model.get('variants'));
        var variant = {}
        variant[name] = weight / 100;
        variants.push(variant);
        this.model.set({variants: variants});
    },
    removeVariant: function(e){
        var index = $(e.target).data('index');
        var variants = _.clone(this.model.get('variants'));
        variants.splice(index, 1);
        this.model.set({variants: variants});
    },
    updateExperimentName: function(e){
        this.model.set('name', $(e.target).val());
    },
    updateVariantName: function(e){
        var $input = $(e.target);
        var index = +$input.data('index');
        var name = $input.val();
        var variants = _.clone(this.model.get('variants'));
        var current = variants[index];
        var currentName = Object.keys(current)[0];
        var currentVal = current[currentName];

        current[name] = currentVal
        delete current[currentName];
        this.model.set({variants: variants});
    },
    updateVariantWeight: function(e){
        var $input = $(e.target);
        var index = +$input.data('index');
        var variants = _.clone(this.model.get('variants'));
        var current = variants[index];
        current[Object.keys(current)[0]] = (+$input.val()) / 100;
        this.model.set({variatns: variants});
    },
    saveExperiment: function(e){
        e.preventDefault();
        var self = this;
        this.model.save(null, {
            method: 'create',
            url: '/test_wrangler/api/experiments',
            success: function(){
                Backbone.history.trigger('beforePageChange');
                Backbone.history.navigate("/experiments/" + self.model.attributes.name, {trigger: true});
            },
            error: function(model, response){
                self.handleError(response.status);
            }
        });
    },
    handleError: function(status){
        var message;

        switch(status){
            case 409:
                message = "Experiment name is already taken"
                break;
            case 422:
                message = "Your experiment must have a name and at least one variant"
                break;
            default:
                message = "An error occured on the server, check your data and try again"
                break;
        }

        this.$el.prepend($("<strong id=\"errors\">Error: " + message + "</strong>"));
    }
});