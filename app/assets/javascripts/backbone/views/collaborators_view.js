Rosa.Views.CollaboratorsView = Backbone.View.extend({
    initialize: function() {
        this.setupDeleter();
        this.$el = $('#collaborators > tbody');
        this.collection.on('reset', this.render, this);
    },

    addOne: function(collaborator) {
        var cView = new Rosa.Views.CollaboratorView({ model: collaborator });
        this.$el.append(cView.render().$el);
    },

    render: function() {
        this.$el.empty();
        this.collection.forEach(this.addOne, this);
        //if (this.collection.where({ removed: true }).length > 0) {
            this._$deleter.show();
        //} else {
        //    this._$deleter.hide();
        //}
        return this;
    },

    setupDeleter: function() {
        this._$deleter = $('#collaborators_deleter');
        this._$deleter.on('click.deleter', '', {context: this}, this.deleterClick);
        this._$deleter.attr('title', 'Remove selected rows');
    },

    deleterClick: function(e) {
        e.data['context'].collection.removeMarked();
    }
});
