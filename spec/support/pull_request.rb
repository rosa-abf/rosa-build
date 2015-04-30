def create_pull_request(project)
  pull = project.pull_requests.new issue_attributes: {title: 'test', body: 'testing'}
  pull.issue.user, pull.issue.project = project.owner, pull.to_project
  pull.to_ref = 'master'
  pull.from_project, pull.from_ref = project, 'non_conflicts'
  pull.save
  pull
end