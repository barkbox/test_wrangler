var BaseCriterion = Backbone.Model.extend({
    defaults: {
        rules: []
    },
    addRule: function(rule){
        var rules = _.clone(this.get('rules'));
        rules.push(rule);
        this.set('rules', rules);
    },
    removeRule: function(index){
        var rules = _.clone(this.get('rules'));
        this.rules.splice(index, 1);
        this.set('rules', rules);
    },
    sync: null,
    save: null,
    toJSON: function(){
        var data = {type: this.type};
        data[this.type] = this.get('rules');
        return data;
    }
});