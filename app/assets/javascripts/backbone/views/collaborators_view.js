Rosa.Views.CollaboratorsView = Backbone.View.extend({
    initialize: function() {
        _.bindAll(this, 'deleterClick', 'processFilter', 'addOne');
        this.setupDeleter();
        this.setupFilter();
        this.$el = $('#collaborators > tbody');
        this.collection.on('reset', this.render, this);
        this.collection.on('add', this.clearFilter, this);
    },

    addOne: function(collaborator) {
        var cView = new Rosa.Views.CollaboratorView({ model: collaborator });
        this.$el.append(cView.render().$el);
    },

    render: function() {
        this.clearFilter();
        this.$el.empty();
        this.collection.forEach(this.addOne, this);
        this._$deleter.show();
        return this;
    },

    renderList: function(list) {
        this.$el.empty();

        list.each(this.addOne);
        return this;
    },

    setupDeleter: function() {
        this._$deleter = $('#collaborators_deleter');
        this._$deleter.on('click.deleter', this.deleterClick);
        this._$deleter.attr('title', 'Remove selected rows');
    },

    deleterClick: function() {
        this.collection.removeMarked();
    },

    setupFilter: function() {
        this._$filter = $('#collaborators thead input[type="text"]');
        this._$filter.on('keyup', this.processFilter);
        this.clearFilter();
    },

    clearFilter: function() {
        this._$filter.val('');
    },

    processFilter: function() {
        var term = this._$filter.val();
        var list = this.collection.filterByName(term, {excludeRemoved: true});
        console.log(list);
        this.renderList(list);
    }
});
