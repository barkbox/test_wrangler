var ExperimentsView = TestWranglerView.extend({
    tagName: 'main',
    className: 'experiment index',
    templates: {index: 'experiments/index'},
    ready: function(){
        this.render();
    },
    render: function(){
        this.$el.html(this.templates['index'](this.collection.models));
        $('body').append(this.$el);
        return this;
    }
})