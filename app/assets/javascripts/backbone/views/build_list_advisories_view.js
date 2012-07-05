Rosa.Views.BuildListAdvisoriesView = Backbone.View.extend({
    initialize: function() {
        _.bindAll(this, 'showAdvisory', 'showPreview', 'showForm',
            'showSearch', 'hideAll', 'displayStatus', 'processSearch',
            'showInTypeSelect', 'typeSelectChange');

        this.$el              = $('#advisory_block'); 
        this._$type_select    = $('#build_list_update_type');
        this._$publish_button = $('input[type="submit"][name="publish"]');

        this._$form           = this.$('#new_advisory_form');
        this._$preview        = this.$('#advisory_preview');

        this._$search         = this.$('#advisory_search_block');
        this._$search_field   = this.$('#advisory_search');
        this._$not_found      = this.$('#advisory_search_block > .advisory_not_found');
        this._$server_error   = this.$('#advisory_search_block > .server_error');
        this._$continue_input = this.$('#advisory_search_block > .continue_input');
        this._search_timer    = null;

        this._$selector       = this.$('#attach_advisory');

        this._state_vars = {};
        this._state_vars = _.extend({
            checked_update_type: this._$type_select.val(),
            header_text:         this._$preview.children('h3').html()
        }, this.state_vars);

        this._$selector.on('change', this.showAdvisory);
        this._$search_field.on('input keyup', this.processSearch);

        this._$type_select.on('change', this.typeSelectChange);

        this.model.on('search:start', function() {
            this._$publish_button.prop({disabled: true});
        }, this);
        this.model.on('search:end', this.showPreview, this);
        this.model.on('search:failed', this.handleSearchError, this);
    },

    showAdvisory: function(ev) {
        this._$publish_button.prop({disabled: false});
        switch (this._$selector.val()) {
            case 'no': 
                this.hideAll();
                this.showInTypeSelect('all');
                break
            case 'new':
                this.showForm();
                this.showInTypeSelect('advisoriable');
                break
            default:
                this.showSearch();
                this.showInTypeSelect('advisoriable');
                this._$publish_button.prop({disabled: true});
        }
    },

    typeSelectChange: function(ev) {
        switch (this._$selector.val()) {
            case 'no':
                this._state_vars.checked_update_type = this._$selector.val();
                break
            case 'new':
                break
            default:
                this._$search_field.trigger('input');
        }
    },

    showInTypeSelect: function(type) {
        var children = this._$type_select.children('option');
        if (type != 'all') {
            var visible_ch = children.filter('.' + type);
            var sel = children.filter(':selected');

            children.prop('disabled', true);
            visible_ch.prop('disabled', false);
            if (sel.prop('disabled')) {
                sel.prop('selected', false);
                visible_ch.first().prop('selected', true);
            }
        } else {
            children.prop('disabled', false).prop('selected', false);
            children.filter('option[value="' + this._state_vars.checked_update_type + '"]').prop('selected', true);
        }
    },

    processSearch: function(ev) {
        if (ev.type == "keyup") {
            if (ev.keyCode != 13) {
                return
            } else {
                ev.preventDefault();
            }
        }

        var TIMER_INTERVAL = 500;

        var self = this;

        var timerCallback = function() {
            if (self._$search_field.val().length > 3) {
                // real search
                self.model.findByAdvisoryID(self._$search_field.val(), self._$type_select.val());
            } else {
                // hide preview if nothing to show
                if (self._$preview.is(':visible')) {
                    self._$preview.slideUp();
                }
                self.displayStatus('found');
            }
        };

        if (this.model.get('advisory_id') == this._$search_field.val()) {
            this.showPreview();
            return;
        }
        // timeout before real AJAX request
        clearTimeout(this._search_timer);
        this._search_timer = setTimeout(timerCallback, TIMER_INTERVAL);
    },

    showPreview: function(id) {
        this._$publish_button.prop({disabled: false});
        if (this._$form.is(':visible')) {
            this._$form.slideUp();
        }
        var prev = this._$preview;
        var adv  = this.model;
        if (adv.get('found')) {
            this._$selector.children('option.advisory_id').val(adv.get('advisory_id'));

            prev.children('h3').html(this._state_vars.header_text + ' ' + adv.get('advisory_id'));
            prev.children('.descr').html(adv.get('description'));
            prev.children('.refs').html(adv.get('references'));
            if (!this._$preview.is(':visible')) {
                this._$preview.slideDown();
            } 
            this.displayStatus('found');
        } else {
            if (this._$preview.is(':visible')) {
                this._$preview.slideUp();
            } 
            this._$publish_button.prop({disabled: true});
            this.displayStatus('not_found');
            this._$selector.children('option.advisory_id').val('');
        }
    },

    showForm: function() {
        if (this._$preview.is(':visible')) {
            this._$preview.slideUp();
        }
        if (this._$search.is(':visible')) {
            this._$search.slideUp();
        }
        if (!this._$form.is(':visible')) {
            this._$form.slideDown();
        }
    },

    showSearch: function() {
        if (this._$form.is(':visible')) {
            this._$form.slideUp();
        }
        if (!this._$search.is(':visible')) {
            this._$search.slideDown();
            this._$search_field.trigger('input');
        }
    },

    handleSearchError: function() {
        this._$publish_button.prop({disabled: true});
        this.displayStatus('error');
        if (this._$preview.is(':visible')) {
            this._$preview.slideUp();
        }
        if (this._$form.is(':visible')) {
            this._$form.slideUp();
        }
    },

    hideAll: function() {
        if (this._$preview.is(':visible')) {
            this._$preview.slideUp();
        }
        if (this._$search.is(':visible')) {
            this._$search.slideUp();
        }
        if (this._$form.is(':visible')) {
            this._$form.slideUp();
        }
    },

    displayStatus: function(st) {
        var ELEMS = {
            'found':     this._$continue_input,
            'not_found': this._$not_found,
            'error':     this._$server_error
        };

        this._$continue_input.hide();
        this._$not_found.hide();
        this._$server_error.hide();

        ELEMS[st].show();
    },

    render: function() {
        this.showAdvisory();
        return this;
    }

});
