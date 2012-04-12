Rosa.Routers.CollaboratorsRouter = Backbone.Router.extend({
    routes: {},

    initialize: function() { 
        this.collaboratorsCollection = new Rosa.Collections.CollaboratorsCollection(Rosa.bootstrapedData.collaborators, { url: window.location.pathname });
        this.searchCollection = new Rosa.Collections.CollaboratorsCollection(null, { url: window.location.pathname + '/find' });
        this.tableView = new Rosa.Views.CollaboratorsView({ collection: this.collaboratorsCollection });
        this.addView = new Rosa.Views.AddCollaboratorView({ collection: this.searchCollection });

        this.addView.on('collaborator_prepared', this.collaboratorsCollection.saveAndAdd, this.collaboratorsCollection);

        this.tableView.render();
        this.addView.render();
    }
}); 
