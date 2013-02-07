Rosa.Views.ProjectModifyView = Backbone.View.extend({
  initialize: function() {
    _.bindAll(this, 'checkboxClick');

    this.$checkbox_wrapper  = $('#niceCheckbox1');
    this._$checkbox         = this.$checkbox_wrapper.children('#project_is_package').first();
    this.$maintainer_form   = $('#maintainer_form');
    this.$publish_form      = $('#publish_form');
    this._$publish_checkbox = this.$publish_form.find('#project_publish_i686_into_x86_64').first();
    
    this.$checkbox_wrapper.on('click', this.checkboxClick);
  },
  
  checkboxClick: function() {
    if (this._$checkbox.is(':checked')) {
      this.$maintainer_form.slideDown();
      this.$publish_form.slideDown();
    } else {
      this.$maintainer_form.slideUp();
      this.$publish_form.slideUp();
      if (this._$publish_checkbox.is(':checked')) {
        changeCheck(this.$publish_form.find('.niceCheck-main'));
      }
    }
  },

  render: function() {
    this.checkboxClick();
  }
});
