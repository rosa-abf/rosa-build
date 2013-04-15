class Hook < ActiveRecord::Base
  include Modules::Models::WebHooks
  belongs_to :project

  before_validation :cleanup_data
  validates :project_id, :data, :presence => true
  validates :name, :presence => true, :inclusion => {:in => NAMES}

  attr_accessible :data, :name

  serialize :data,  Hash

  scope :for_name, lambda {|name| where(:name => name) if name.present? }

  def issue_hook(issue)
    params = {
      'data'     => data.to_json,
      'payload'  => meta(issue.project, issue.user).merge(
        :action => (issue.closed? ? 'closed' : 'opened'),
        :issue  => {
          :number => issue.serial_id,
          :state  => issue.status,
          :title  => issue.title,
          :body   => issue.body,
          :user   => {:login => issue.user.uname},
          :html_url => "#{issue.project.html_url}/issues/#{issue.serial_id}"
        }
      ).to_json
    }
    uri   = URI "http://127.0.0.1:8080/#{name}/issues"
    begin
      res = Net::HTTP.post_form(uri, params)
    rescue # Dont care about it
    end
  end
  later :issue_hook, :queue => :clone_build


  protected

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
