Rosa.Routers.CollaboratorsRouter = Backbone.Router.extend({
    routes: {},

    initialize: function() { 
        this.collaboratorsCollection = new Rosa.Collections.CollaboratorsCollection(Rosa.bootstrapedData.collaborators);
        this.usersView = new Rosa.Views.CollaboratorsView({collection_type: 'user', collection: this.collaboratorsCollection});
        this.groupsView = new Rosa.Views.CollaboratorsView({collection_type: 'group', collection: this.collaboratorsCollection});

        this.usersView.render();
        this.groupsView.render();
    }
}); 
