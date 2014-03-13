var ProjectRef = function(atts) {
  var self = this;
  var initialSettings = atts || {};
  //initial settings if passed in
  for(var setting in initialSettings){
    if(initialSettings.hasOwnProperty(setting))
      self[setting] = initialSettings[setting];
  };



  //with some logic...
  self.isTag = self.object.type == 'tag';
  self.ui_container = false;

  self.path = function(project) {
    return Routes.tree_path(project.fullname, self.ref);
  }

  self.diff_path = function(project, current_ref) {
    return Routes.diff_path(project.fullname, current_ref + '...' + self.ref);
  }

  self.archive_path = function(project, type) {
    return Routes.archive_path(project.fullname, project.name + '-' + self.ref, {format: type});
  }

  //return the scope-safe instance
  return self;
};