Rosa.Models.Collaborator = Backbone.Model.extend({
    paramRoot: 'collaborator',

    defaults: {
        id: null,
        name: null,
        role: null,
        removed: false
    },

    changeRole: function(r) {
        this._prevState = this.get('role');
        this.save({role: r},
                  {wait: true,
                   error: function(model, response) {
                       model.set({role: model._prevState});
                   }
        });
        return this;
    },
    toggleRemoved: function() {
        if (this.get('removed') === false) {
            this.set({removed: true});
        } else { 
            this.set({removed: false});
        }
        return this;
    }
});

Rosa.Collections.CollaboratorsCollection = Backbone.Collection.extend({
    model: Rosa.Models.Collaborator,

    initialize: function() {
        this.url = window.location.pathname;
        this.on('change:removed add', this.sort, this);
    },
    comparator: function(m) {
        return ((m.get('removed') === true) ? '0' : '1') + m.get('name');
    },

    removeMarked: function(params) {
        var marked = this.where({removed: true});
        if (params['type'] !== undefined) {
            marked = marked.where({type: params['type']});
        }
        marked.forEach(function(el) {
            el.destroy({wait: true, silent: true});
        });
//        this.trigger('reset');
    }
});
