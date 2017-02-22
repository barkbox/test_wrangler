var UserAgentCriterion = BaseCriterion.extend({
    defaults: {
        type: 'user_agent'
    },
    toJSON: function(){
        return { type: 'user_agent', 'user_agent': this.get('rules').map(function(rule){
            return rule.value;
        })}
    }
});