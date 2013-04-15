class Hook < ActiveRecord::Base
  include Modules::Models::WebHooks
  belongs_to :project

  before_validation :cleanup_data
  validates :project_id, :data, :presence => true
  validates :name, :presence => true, :inclusion => {:in => NAMES}

  attr_accessible :data, :name

  serialize :data,  Hash

  scope :for_name, lambda {|name| where(:name => name) if name.present? }

  def issue_hook(issue, action)
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
            :html_url => "#{repo_owner}/pull_requests/#{pull.serial_id}"
          )
        ).to_json
      }
    else
      post 'issues', {
        :payload => payload.merge(
          :action => (issue.closed? ? 'closed' : 'opened'),
          :issue  => base_params.merge(
            :html_url => "#{repo_owner}/issues/#{issue.serial_id}"
          )
        ).to_json
      }
    end
  end
  later :issue_hook, :queue => :clone_build

  protected

  def post(action, params)
    uri   = URI "http://127.0.0.1:8080/#{name}/#{action}"
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
      :sender => {:login => user.uname}
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
