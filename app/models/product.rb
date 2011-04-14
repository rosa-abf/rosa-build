class Product < ActiveRecord::Base
  NEVER_BUILT = 2
  BUILD_COMPLETED = 0
  BUILD_FAILED = 1

  validates :name, :presence => true, :uniqueness => true
  validates :platform_id, :presence => true
  validates :build_status, :inclusion => { :in => [ NEVER_BUILT, BUILD_COMPLETED, BUILD_FAILED ] }

  belongs_to :platform

  has_attached_file :tar
  validates_attachment_content_type :tar, :content_type => ["application/gnutar", "application/x-compressed", "application/x-gzip"], :message => I18n.t('layout.products.invalid_content_type')

  after_validation :merge_tar_errors

  scope :recent, order("name ASC")

  before_save :destroy_tar?

  def delete_tar
    @delete_tar ||= "0"
  end

  def delete_tar=(value)
    @delete_tar = value
  end

  protected

    def destroy_tar?
      self.tar.clear if @delete_tar == "1"
    end

    def merge_tar_errors
      errors[:tar] += errors[:tar_content_type]
      errors[:tar_content_type] = []
    end


end
