class Product < ActiveRecord::Base
  ATTRS_TO_CLONE = [ 'build_path', 'build_script', 'counter', 'ks', 'menu', 'tar', 'use_cron', 'cron_tab' ]

  belongs_to :platform
  has_many :product_build_lists, :dependent => :destroy
  has_many :relations, :as => :target, :dependent => :destroy

  after_validation :merge_tar_errors
  before_save :destroy_tar?
  after_create :add_admin_relations

  has_attached_file :tar

  validates_attachment_content_type :tar, :content_type => ["application/gnutar", "application/x-compressed", "application/x-gzip", "application/x-bzip2", "application/x-tar"], :message => I18n.t('layout.products.invalid_content_type')
  validates :name, :presence => true, :uniqueness => {:scope => :platform_id}

  scope :recent, order("name ASC")

  def delete_tar
    @delete_tar ||= "0"
  end

  def delete_tar=(value)
    @delete_tar = value
  end

  def can_clone?
    is_template
  end

  def can_build?
    !is_template
  end

  def clone_from!(template)
    raise "Only templates can be cloned" unless template.can_clone?
    attrs = ATTRS_TO_CLONE.inject({}) {|result, attr|
      result[attr] = template.send(attr)
      result
    }

    self.attributes = attrs
  end

  def cron_command
    self.name
  end

  def cron_tab
    @cron_tab ||= self[:cron_tab].present? ? self[:cron_tab] : "* * * * *"
  end

  ["minutes", "hours", "days", "months", "weekdays"].each_with_index do |meth, index|
    class_eval <<-EOF
      def cron_tab_#{meth}
        value = cron_tab.split(/\s+/)[#{index}]
        value == "*" ? [] : value.split(/\s*,*\s*/).collect{|x| x.to_i }
      end

      EOF
  end

  def full_clone(attrs) # owner
    clone.tap do |c| # dup
      c.attributes = attrs
      c.updated_at = nil; c.created_at = nil # :id = nil
    end
  end

  protected

    def destroy_tar?
      self.tar.clear if @delete_tar == "1"
    end

    def merge_tar_errors
      errors[:tar] += errors[:tar_content_type]
      errors[:tar_content_type] = []
    end

    def add_admin_relations
      platform.relations.where(:role => 'admin').each do |rel|
        r = relations.build(:role => 'admin', :object_type => rel.object_type)
        r.object_id = rel.object_id
        r.save
      end
    end

end
