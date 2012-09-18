Rosa.Views.ProjectModifyView = Backbone.View.extend({
  initialize: function() {
    _.bindAll(this, 'checkboxClick');

    this.$checkbox_wrapper = $('#niceCheckbox1');
    this._$checkbox        = this.$checkbox_wrapper.children('#project_is_package').first();
    this.$maintainer_form  = $('#maintainer_form');
    
    this.$checkbox_wrapper.on('click', this.checkboxClick);
  },
  
  checkboxClick: function() {
    if (this._$checkbox.is(':checked')) {
      this.$maintainer_form.slideDown();
    } else {
      this.$maintainer_form.slideUp();
    }
  },

  render: function() {
    this.checkboxClick();
  }
});
