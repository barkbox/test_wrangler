$(function(){
    new ExperimentsRouter()
    Backbone.history.start({pushState: true, root: "/test_wrangler/dashboard/"});
});
