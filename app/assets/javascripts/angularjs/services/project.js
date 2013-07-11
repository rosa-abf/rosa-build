var ApiProject = function($resource) {

  var projectResource = $resource('/api/v1/projects/:project_id.json');
  var queryProject    = function(project_id, next) {
    projectResource.get({project_id: project_id}, function(results){
      next(new Project(results.project));
    });
  };

  var refsResource  = $resource('/api/v1/projects/:project_id/refs_list.json');
  var queryRefs     = function(project_id, next) {
    //use a callback instead of a promise
    refsResource.get({project_id: project_id}, function(results) {
      var out = [];
      //Underscore's "each" method
      _.each(results.refs_list, function(ref){
        //using our ProjectRef(ref) prototype above
        out.push(new ProjectRef(ref));
      });
      next(out);
    });
  };

  return {
    refs    : queryRefs,
    project : queryProject
  }
}

RosaABF.factory("ApiProject", ApiProject);