var UniversalCriterion = BaseCriterion.extend({
    defaults: {
        type: 'universal',
        rules: []
    },
    addRule: null,
    removeRule: null,
    toJSON: function(){
        return {type: 'universal'};
    }
});