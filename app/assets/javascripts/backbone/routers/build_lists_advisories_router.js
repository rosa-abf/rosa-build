Rosa.Routers.BuildListsAdvisoriesRouter = Backbone.Router.extend({
    routes: {},

    initialize: function() {
        this.advisoriesCollection = new Rosa.Collections.AdvisoriesCollection(Rosa.bootstrapedData.advisories);
        this.advisoriesView = new Rosa.Views.BuildListAdvisoriesView({ collection: this.advisoriesCollection });

        this.advisoriesView.render();
    }
});
