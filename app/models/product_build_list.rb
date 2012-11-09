# -*- encoding : utf-8 -*-
class ProductBuildList < ActiveRecord::Base
  include Modules::Models::CommitAndVersion
  delegate :url_helpers, to: 'Rails.application.routes'

  BUILD_STARTED = 2
  BUILD_COMPLETED = 0
  BUILD_FAILED = 1

  STATUSES = [  BUILD_STARTED,
                BUILD_COMPLETED,
                BUILD_FAILED
              ]

  HUMAN_STATUSES = { BUILD_STARTED => :build_started,
                     BUILD_COMPLETED => :build_completed,
                     BUILD_FAILED => :build_failed
                    }

  belongs_to :product
  belongs_to :project


  validates :product_id, :status, :project_id, :main_script, :presence => true
  validates :status, :inclusion => { :in => [BUILD_STARTED, BUILD_COMPLETED, BUILD_FAILED] }

  attr_accessor :base_url
  attr_accessible :status, :base_url, :branch, :project_id, :main_script, :params, :project_version, :commit_hash
  attr_readonly :product_id
  serialize :results, Array


  scope :default_order, order('updated_at DESC')
  scope :for_status, lambda {|status| where(:status => status) }
  scope :for_user, lambda { |user| where(:user_id => user.id)  }
  scope :scoped_to_product_name, lambda {|product_name| joins(:product).where('products.name LIKE ?', "%#{product_name}%")}
  scope :recent, order("#{table_name}.updated_at DESC")

  after_create :xml_rpc_create
  before_destroy :can_destroy?
  after_destroy :xml_delete_iso_container

  def container_path
    "/downloads/#{product.platform.name}/product/#{id}/"
  end

  def event_log_message
    {:product => product.name}.inspect
  end

  def self.human_status(status)
    I18n.t("layout.product_build_lists.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
  end

  def can_destroy?
    [BUILD_COMPLETED, BUILD_FAILED].include? status
  end

  protected

  def xml_rpc_create
    file_name = "#{project.owner.uname}-#{project.name}-#{commit_hash}"
    srcpath = url_helpers.archive_url(
      project.owner,
      project.name,
      file_name,
      'tar.gz',
      :host => ActionMailer::Base.default_url_options[:host]
    )
    options = {
      :id => id,
      # TODO: revert changes
      :srcpath => 'http://dl.dropbox.com/u/945501/avokhmin-test-iso-script-5d9b463d4e9c06ea8e7c89e1b7ff5cb37e99e27f.tar.gz',
      :params => params,
      :main_script => main_script
    }
    Resque.push(
      'iso_worker',
      'class' => 'AbfWorker::IsoWorker',
      'args' => [options]
    )
    return true
  end  

  def xml_delete_iso_container
    # TODO: write new worker for delete
    if project
      raise "Failed to destroy product_build_list #{id} inside platform #{product.platform.name} (Not Implemented)."
    else
      result = ProductBuilder.delete_iso_container self
      if result == ProductBuilder::SUCCESS
        return true
      else
        raise "Failed to destroy product_build_list #{id} inside platform #{product.platform.name} with code #{result}."
      end
    end
  end
end
