$(function(){
    new ExperimentsRouter();
    new CohortsRouter();
    Backbone.history.start({pushState: true, root: "/test_wrangler/dashboard/"});
    var bbRoot = Backbone.history.root.replace(/^\//, '').replace(/\/$/, '');
    var bbRootRegexp = new RegExp(bbRoot);
    
    $(document.body).on('click', 'a', function(e) {
        window.addEventListener('popstate', function(e){
            Backbone.history.trigger('beforePageChange');
        });
        var href = $(this).attr('href').replace(/^\/+/, '').replace(/\/+$/, '');
            if (bbRootRegexp.test(href)) {
                href = href.replace(bbRootRegexp, '').replace(/^\/+/, '').replace(/\/+$/, '');
                Backbone.history.handlers.find(function(handler) {
                    if (handler['route'].test(href)) {
                        e.preventDefault();
                        Backbone.history.trigger('beforePageChange');
                        Backbone.history.navigate(href, {trigger: true});
                        return true;
                    }
                });
            }
    })
});
