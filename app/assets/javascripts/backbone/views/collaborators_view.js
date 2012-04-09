Rosa.Views.CollaboratorsView = Backbone.View.extend({
    initialize: function() {
        this._type = this.options['collection_type'];
        this.setupDeleter();
        this.$el = $('#' + this._type + 's_collaborators > tbody');
        this.collection.on('add', this.addOne, this);
        this.collection.on('reset', this.render, this);
    },

    addOne: function(collaborator) {
        if (collaborator.get('type') === this._type) {
            var cView = new Rosa.Views.CollaboratorView({ model: collaborator });
            this.$el.append(cView.render().el);
        };
    },

    render: function() {
        this.$el.empty();
        var col = new Rosa.Collections.CollaboratorsCollection(this.collection.where({type: this._type}));
        col.forEach(this.addOne, this);
        if (col.where({ removed: true }).length > 0) {
            this._$deleter.show();
        } else {
            this._$deleter.hide();
        }
        return this;
    },

    setupDeleter: function() {
        this._$deleter = $('#' + this._type + 's_deleter');
        this._$deleter.on('click.deleter', '', {context: this}, this.deleterClick);
        this._$deleter.attr('title', 'Remove selected rows');
    },

    deleterClick: function(e) {
        e.data['context'].collection.removeMarked({type: this._type});
    }
});
