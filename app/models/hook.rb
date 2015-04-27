class Hook < ActiveRecord::Base
  include WebHooks
  include UrlHelper
  include Rails.application.routes.url_helpers

  belongs_to :project

  before_validation :cleanup_data
  validates :project, :data, presence: true
  validates :name, presence: true, inclusion: {in: NAMES}

  # attr_accessible :data, :name

  serialize :data,  Hash

  scope :for_name, ->(name) { where(name: name) if name.present? }

  def receive_issues(issue, action)
    pull = issue.pull_request
    return if action.to_sym == :create && pull
    default_url_options

    payload = meta(issue.project, issue.user)
    base_params = {
      number: issue.serial_id,
      state:  issue.status,
      title:  issue.title,
      body:   issue.body,
      user:   {login: issue.user.uname},
    }
    if pull
      total_commits = pull.repo.commits_between(pull.to_commit, pull.from_commit).count
      repo_owner = pull.to_project.owner.uname
      post 'pull_request', {
        payload: payload.merge(
          action: (pull.ready? ? 'opened' : pull.status),
          pull_request: base_params.merge(
            commits:    total_commits,
            head:       {label: "#{pull.from_project.owner.uname}:#{pull.from_ref}"},
            base:       {label: "#{repo_owner}:#{pull.to_ref}"},
            html_url:   project_pull_request_url(pull.to_project, pull)
          )
        ).to_json
      }
    else
      post 'issues', {
        payload: payload.merge(
          action: (issue.closed? ? 'closed' : 'opened'),
          issue:  base_params.merge(
            html_url: project_issue_url(issue.project, issue)
          )
        ).to_json
      }
    end
  end
  later :receive_issues, queue: :notification

  def receive_push(git_hook)
    default_url_options
    project = Project.find(git_hook['project']['id'])
    user    = User.find(git_hook['user']['id'])
    payload = meta(project, user)
    oldrev, newrev, change_type = git_hook.values_at *%w(oldrev newrev change_type)

    commits = []
    payload.merge!(before: oldrev, after: newrev)
    if %w(delete create).exclude? change_type
      payload.merge!(
        :compare  => diff_url(project, "#{oldrev[0..6]}...#{newrev[0..6]}")
      )
      if oldrev == newrev
        commits   = [project.repo.commit(newrev)]
        modified  = commits.first.stats.files.map{|f| f[0]}
      else
        commits = project.repo.commits_between(oldrev, newrev)
      end
    end

    post 'push', {
      payload: payload.merge(
        ref: git_hook['refname'],
        commits: commits.map{ |commit|
          files = changed_files commit
          {
            id:         commit.id,
            message:    commit.message,
            distinct:   true,
            url:        commit_url(project, commit),
            removed:    files[:removed],
            added:      files[:added],
            modified:   files[:modified],
            timestamp:  commit.committed_date,
            author:     {name: commit.committer.name, email: commit.committer.email}
          }
        }
      ).to_json
    }
  end
  later :receive_push, queue: :notification

  protected

  def post(action, params)
    github_services = APP_CONFIG['github_services']
    uri   = URI "http://#{github_services['ip']}:#{github_services['port']}/#{name}/#{action}"
    Net::HTTP.post_form uri, params.merge(data: data.to_json)
  rescue # Dont care about it
  end

  def meta(project, user)
    {
      repository: {
        name:  project.name,
        url:   project_url(project),
        owner: { login: project.owner.uname }
      },
      sender: {login: user.uname},
      pusher: {name: user.uname}
    }
  end

  def cleanup_data
    if self.name.present? && fields = SCHEMA[self.name.to_sym]
      new_data = {}
      fields.each { |type, field| new_data[field] = self.data[field] }
      self.data = new_data
    end
  end

  def changed_files(commit)
    removed, added, modified = [], [], []
    commit.show.each do |diff|
      if diff.renamed_file
        added     << diff.b_path
        removed   << diff.a_path
      elsif diff.new_file
        added     << diff.b_path
      elsif diff.deleted_file
        removed   << diff.a_path
      else
        modified  << diff.a_path
      end
    end
    { removed: removed, added: added, modified: modified }
  end

end
