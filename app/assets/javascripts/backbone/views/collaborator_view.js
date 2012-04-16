Rosa.Views.CollaboratorView = Backbone.View.extend({
    template: JST['backbone/templates/collaborators/collaborator'],
    tagName: 'tr',
    className: 'regular',

    events: {
        'change input[type="radio"]':    'changeRole',
        'change input[type="checkbox"]': 'toggleRemoved'
    },

    initialize: function() {
        this.$el.attr('id', 'admin-table-members-row' + this.options.model.get('id') + this.options.model.get('actor_type'));
        this.model.on('change', this.render, this);
        this.model.on('destroy', this.hide, this);
        this.model.on('sync_failed', this.syncError, this);
        this.model.on('sync_success', this.syncSuccess, this);
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
        this.model.toggleRemoved();
    },

    hide: function() {
        this.remove();
    },

    syncError: function() {
        var self = this;
        this.$el.addClass('sync_error');
        this.$('td').animate({
            'background-color': '#FFFFFF'
        }, {
            duration: 1500,
            easing: 'easeInCirc',
            complete: function() {
                self.$el.removeClass('sync_error');
            }
        });
    },

    syncSuccess: function() {
        var self = this;
        this.$el.addClass('sync_success');
        this.$('td').animate({
           'background-color': '#FFFFFF'
        }, {
            duration: 1500,
            easing: 'easeInCirc',
            complete: function() {
                self.$el.removeClass('sync_success');
            }
        });
    }
});
