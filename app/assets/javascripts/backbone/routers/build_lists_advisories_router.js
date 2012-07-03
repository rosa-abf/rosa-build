Rosa.Routers.BuildListsAdvisoriesRouter = Backbone.Router.extend({
    routes: {},

    initialize: function() {
        this.advisoriesView = new Rosa.Views.BuildListAdvisoriesView({ model: new Rosa.Models.Advisory() });

        this.advisoriesView.render();
    }
});
