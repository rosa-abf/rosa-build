Rosa.Views.CollaboratorView = Backbone.View.extend({
    template: JST['backbone/templates/collaborators/collaborator'],
    tagName: 'tr',

    events: {
        'change input[type="radio"]':    'changeRole',
        'change input[type="checkbox"]': 'toggleRemoved'
    },

    initialize: function() {
        this.$el.attr('id', 'admin-table-members-row' + this.options.model.get('id') + this.options.model.get('type'));
        this.model.on('change', this.render, this);
        this.model.on('destroy', this.hide, this);
    },

    render: function() {
        if (this.model.get('removed')) {
            this.$el.addClass('removed');
        } else {
            this.$el.removeClass('removed');
        };
        this.$el.html(this.template(this.model.toJSON()));
        return this;
    },

    changeRole: function(e) {
        this.model.changeRole(e.target.value);
    },

    toggleRemoved: function(e) {
        //var mod = this.model
        //this.$el.addClass('removed').fadeOut(1000, function() { mod.toggleRemoved() });
        this.model.toggleRemoved();
    },

    hide: function() {
        this.remove();
    }
});
