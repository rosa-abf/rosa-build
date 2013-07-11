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

  self.path = function(project) {
    return '/' + project.fullname + '/tree/' + self.ref;
  }

  self.diff_path = function(project, current_ref) {
    return '/' + project.fullname + '/diff/' + current_ref + '...' + self.ref;
  }

  //return the scope-safe instance
  return self;
};