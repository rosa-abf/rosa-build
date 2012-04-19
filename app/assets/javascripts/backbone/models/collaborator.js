Rosa.Models.Collaborator = Backbone.Model.extend({
    paramRoot: 'collaborator',

    defaults: {
        id:         null,
        actor_id:   null,
        actor_name: null,
        actor_type: null,
        avatar:     null, 
        actor_path: null,
        project_id: null,
        role:       null, 
        removed:    false
    },

    changeRole: function(r) {
        var self = this;
        this._prevState = this.get('role');
        this.save({role: r},
                  {wait: true,
                   success: function(model, response) {
                       self.trigger('sync_success');
                   },
                   error: function(model, response) {
                       model.set({role: model._prevState});
                       self.trigger('sync_failed');
                   }
        });
        return this;
    },
    setRole: function(r) {
        this.set({ role: r });
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

    initialize: function(coll, opts) {
        if (opts === undefined || opts['url'] === undefined) {
            this.url = window.location.pathname;
        } else {
            this.url = opts['url'];
        }
        this.on('change:removed change:id add', this.sort, this);
    },
    comparator: function(m) {
        var res = ''
        if (m.get('removed') === true) {
            res = 0;
        } else if (m.isNew()) {
            res = 1;
        } else { res = 2 }
        return res + m.get('actor_name');
    },

    removeMarked: function() {
        var marked = this.where({removed: true});
        marked.forEach(function(el) {
            el.destroy({wait: true, silent: true});
        });
    },

    saveAndAdd: function(model) {

        model.urlRoot = this.url;
        var self = this;
        model.save({}, {
            wait: true,
            success: function(m) {
                self.add(m.toJSON());
            }
        });
    },

    filterByName: function(term, options) {
        if (term == "") return this;
        console.log(term);
 
		var pattern = new RegExp(term, "i");
        
		return _(this.filter(function(data) {
            console.log(data.get("actor_name"));
            console.log(pattern.test(data.get("actor_name")));
		  	return pattern.test(data.get("actor_name"));
		}));
    }
});
