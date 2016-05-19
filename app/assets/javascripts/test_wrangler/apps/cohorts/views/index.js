var CohortsView = TestWranglerView.extend({
    tagName: 'main',
    className: 'cohort index',
    templates: {index: 'cohorts/index'},
    ready: function(){
        return this.render();
    },
    render: function(){
        this.$el.html(this.templates['index'](this.collection.models));
        $('body').append(this.$el);
        return this;
    }
});