Rosa.Views.SearchedCollaboratorView = Backbone.View.extend({
    template: JST['backbone/templates/collaborators/searched_collaborator'],
    tagName: 'li',
    className: 'item',

    render: function() {
        this.$el.empty();        
        this.$el.data( "item.autocomplete", this.model )
                .append(this.template(this.model.toJSON()));
        return this;
    }
})
