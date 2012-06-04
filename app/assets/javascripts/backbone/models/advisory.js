Rosa.Models.Advisory = Backbone.Model.extend({
    defaults: {
        id: null,
        description: null,
        references:  null,
        update_type: null
    }
});

Rosa.Collections.AdvisoriesCollection = Backbone.Collection.extend({
    model: Rosa.Models.Advisory
});
