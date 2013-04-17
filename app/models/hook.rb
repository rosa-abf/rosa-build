class Hook < ActiveRecord::Base
  include Modules::Models::WebHooks
  belongs_to :project

  before_validation :cleanup_data
  validates :project_id, :data, :presence => true
  validates :name, :presence => true, :inclusion => {:in => NAMES}

  attr_accessible :data, :name

  serialize :data,  Hash

  scope :for_name, lambda {|name| where(:name => name) if name.present? }

  def receive_issues(issue, action)
    pull = issue.pull_request
    return if action.to_sym == :create && pull

    payload = meta(issue.project, issue.user)
    base_params = {
      :number => issue.serial_id,
      :state  => issue.status,
      :title  => issue.title,
      :body   => issue.body,
      :user   => {:login => issue.user.uname},
    }
    if pull
      total_commits = pull.repo.commits_between(pull.to_commit, pull.from_commit).count
      repo_owner = pull.to_project.owner.uname
      post 'pull_request', {
        :payload => payload.merge(
          :action => (pull.ready? ? 'opened' : pull.status),
          :pull_request  => base_params.merge(
            :commits  => total_commits,
            :head     => {:label => "#{pull.from_project.owner.uname}:#{pull.from_ref}"},
            :base     => {:label => "#{repo_owner}:#{pull.to_ref}"},
            :html_url => "#{issue.project.html_url}/pull_requests/#{pull.serial_id}"
          )
        ).to_json
      }
    else
      post 'issues', {
        :payload => payload.merge(
          :action => (issue.closed? ? 'closed' : 'opened'),
          :issue  => base_params.merge(
            :html_url => "#{issue.project.html_url}/issues/#{issue.serial_id}"
          )
        ).to_json
      }
    end
  end
  later :receive_issues, :queue => :clone_build

  def receive_push(git_hook)
    payload = meta(git_hook.project, git_hook.user)
    commits = []
    oldrev, newrev = git_hook.oldrev, git_hook.newrev
    if git_hook.change_type ==  'delete'
      payload.merge!(:before => oldrev, :after => nil, :compare => nil)
    elsif git_hook.change_type ==  'create'
      payload.merge!(:before => nil, :after => newrev, :compare => nil)
    else
      payload.merge!(
        :before => oldrev, :after => newrev,
        :compare  => "#{git_hook.project.html_url}/compare/#{oldrev[0..6]}...#{newrev[0..6]}"
      )
      if git_hook.message # online update
        commits = [[git_hook.newrev, git_hook.message]]
      else
        commits = git_hook.project.repo.commits_between(git_hook.oldrev, git_hook.newrev)
      end
    end

    post 'push', {
      :payload => payload.merge(
        :ref => git_hook.refname,
        :commits => commits.map{ |c|
          {
            :id => c.id,
            :message => c.message,
            :distinct => true,
            :url => "#{git_hook.project.html_url}/commit/#{c.id}",
            :removed => [],
            :added => [],
            :modified => c.stats.files.map{|f| f[0]},
            :timestamp => c.committed_date,
            :author => {:name => c.committer.name, :email => c.committer.email}
          }
        }
      ).to_json
    }
  end
  later :receive_push, :queue => :clone_build

  protected

  def post(action, params)
    github_services = APP_CONFIG['github_services']
    uri   = URI "http://#{github_services['ip']}:#{github_services['port']}/#{name}/#{action}"
    Net::HTTP.post_form uri, params.merge(:data => data.to_json)
  rescue # Dont care about it
  end

  def meta(project, user)
    {
      :repository => {
        :name  => project.name,
        :url   => project.html_url,
        :owner => { :login => project.owner.uname }
      },
      :sender => {:login => user.uname},
      :pusher => {:name => user.uname}
    }
  end

  def cleanup_data
    if self.name.present? && fields = SCHEMA[self.name.to_sym]
      new_data = {}
      fields.each{ |type, field| new_data[field] = self.data[field] }
      self.data = new_data
    end
  end

end
