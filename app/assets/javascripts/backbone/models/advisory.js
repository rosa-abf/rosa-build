Rosa.Models.Advisory = Backbone.Model.extend({
    defaults: {
        id: null,
        description: null,
        references:  null,
        update_type: null,
        found: false
    },

    initialize: function() {
        _.bindAll(this, 'findByAdvisoryID');

        this.url = '/advisories';
    },

    findByAdvisoryID: function(id, bl_type, options) {
        var self = this;

        var urlError = function() {
            throw new Error("A 'url' property or function must be specified");
        };

        var typeError = function() {
            throw new Error("A 'bl_type' must be 'security' or 'bugfix'");
        };

        var idError = function() {
            throw new Error("A 'id' must be a string at least 4 characters long");
        };

        if ( (typeof(id) != "string") || (id.length < 4) ) {
            idError();
        }

        if ( (bl_type == undefined) || (bl_type == null) || ((bl_type != 'security') && (bl_type != 'bugfix')) ) {
            typeError();
        }

        options |= {};
        var data = _.extend({
            query: id,
            bl_type: bl_type
        }, {});

        var params = _.extend({
            type:         'GET',
            dataType:     'json',
            beforeSend: function( xhr ) {
                var token = $('meta[name="csrf-token"]').attr('content');
                if (token) xhr.setRequestHeader('X-CSRF-Token', token);
              
                self.trigger('search:start');
            }
        }, options);

        if (!params.url) {
            params.url = ((_.isFunction(this.url) ? this.url() : this.url) + '/search') || urlError();
        }

        params.data = data;

        var complete = options.complete;
        params.complete = function(jqXHR, textStatus) {
            //console.log(jqXHR);

            switch (jqXHR.status) {
                case 200:
                    self.set(_.extend({
                        found: true
                    }, JSON.parse(jqXHR.responseText)), {silent: true});
                    self.trigger('search:end');
                    break

                case 404:
                    self.set(self.defaults, {silent: true});
                    self.trigger('search:end');
                    break

                default:
                    self.set(self.defaults, {silent: true});
                    self.trigger('search:failed');
            }

            if (complete) complete(jqXHR, textStatus);
        }

        $.ajax(params);

        return this;
        
    }
});

Rosa.Collections.AdvisoriesCollection = Backbone.Collection.extend({
    model: Rosa.Models.Advisory
});
