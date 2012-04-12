Rosa.Views.AddCollaboratorView = Backbone.View.extend({
    result_empty: JST['backbone/templates/shared/autocomplete_result_empty'],

    events: {
        'click #add_collaborator_button': 'addCollaborator'
    },

    initialize: function() {
        _.bindAll(this, 'getData', 'renderAll', 'onFocus', 'selectItem', 'addCollaborator');

        this.$el            = $('#add_collaborator_form');
        this.$_search_input = this.$('#collaborator_name');
        this.$_image        = this.$('div.img img');
        this.$_role         = this.$('#role');

        this.ac = this.$_search_input.autocomplete({
            minLength: 1,
            source: this.getData,
            focus:  this.onFocus,
            select: this.selectItem
        });
        this.ac.data("autocomplete")._renderItem = this.addOne;
        this.ac.data("autocomplete")._renderMenu = this.renderAll;
    },

    render: function() {
        return this;
    },

    getData: function(request, response) {
        var res = this.collection.fetch({
            data: {term: request.term},
            wait: true,
            success: function(collection) {
                if (collection.length !== 0) {
                    response(collection.models);
                } else {
                    response([{result_empty: true}]);
                }
            }
        });
    },

    addOne: function(ul, item) {
        var v = new Rosa.Views.SearchedCollaboratorView({ model: item });
        return v.render().$el.appendTo(ul);
    },

    renderAll: function( ul, items ) {
        var self = this;
        if (items[0]['result_empty'] !== undefined && items[0]['result_empty'] === true) {
            ul.removeClass('has_results').append(this.result_empty());
        } else {
            ul.addClass('has_results');
            _.each( items, function( item ) {
                self.addOne( ul, item );
            });
        }
    },

    onFocus: function( event, ui ) {
        this.$_search_input.val(ui.item.get('actor_name'));
        return false;
    },

    selectItem: function( event, ui ) {
        var model = ui.item;
        this.$_image.attr('src', model.get('avatar')).show(); 

        this.__selected_item = model;
        return false;
    },

    addCollaborator: function(e) {
        e.preventDefault();
        var model = this.__selected_item;

        if ( model !== undefined ) {
            model.setRole(this.$_role.val());
            this.trigger('collaborator_prepared', model);
            this.__selected_item = undefined;
            this.$_image.hide();
            this.$_search_input.val('');
        }
        return false;
    }

});
