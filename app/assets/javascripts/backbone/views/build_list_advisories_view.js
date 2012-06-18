Rosa.Views.BuildListAdvisoriesView = Backbone.View.extend({
    initialize: function() {
        _.bindAll(this, 'popoverTitle', 'popoverDesc', 'showAdvisory',
                        'changeAdvisoryList', 'showPreview', 'showForm', 'hideAll');
        $('.chzn-select').chosen();
        this.$el = $('#advisory_block'); 
        this._$form = this.$('#new_advisory_form');
        this._$preview = this.$('#advisory_preview');
        this._$type_select = $('#build_list_update_type');
        this._$selector = this.$('#attach_advisory');
        this._header_text = this._$preview.children('h3').html();

        this._$selector.on('change', this.showAdvisory);
        this._$type_select.on('change', this.changeAdvisoryList);
    },

    changeAdvisoryList: function() {
        this.$('.popoverable').hide();
        this.$('.popoverable.' + this._$type_select.val()).show();
        this._$selector.val('no').trigger("liszd:updated").trigger('change');
    },

    popoverTitle: function(el) {
        console.log(el);
        console.log(el.html());
        return el.html();
    },

    popoverDesc: function(el) {
        return this.collection.get(el.html()).get('popover_desc');
    },

    showAdvisory: function(el) {
        var adv_id = this._$selector.val();
        switch (adv_id) {
            case 'no': 
                this.hideAll();
                break
            case 'new':
                this.showForm();
                break
            default:
                this.showPreview(adv_id);
        }
    },

    showPreview: function(id) {
        if (this._$form.is(':visible')) {
            this._$form.slideUp();
        }
        var adv = this.collection.get(id);
        var prev = this._$preview;
        prev.children('h3').html(this._header_text + ' ' + adv.get('advisory_id'));
        prev.children('.descr').html(adv.get('description'));
        prev.children('.refs').html(adv.get('references'));
        if (!this._$preview.is(':visible')) {
            this._$preview.slideDown();
        }
    },

    showForm: function() {
        if (this._$preview.is(':visible')) {
            this._$preview.slideUp();
        }
        if (!this._$form.is(':visible')) {
            this._$form.slideDown();
        }
    },

    hideAll: function() {
        if (this._$preview.is(':visible')) {
            this._$preview.slideUp();
        }
        if (this._$form.is(':visible')) {
            this._$form.slideUp();
        }
    },

    render: function() {
        var title = this.popoverTitle;
        var description = this.popoverDesc;
        this.changeAdvisoryList();
        this.$('.popoverable').popover({
            title: function() { return title($(this)); },
            content: function() { return description($(this)); }
        });
        this.showAdvisory();
        return this;
    }

});
