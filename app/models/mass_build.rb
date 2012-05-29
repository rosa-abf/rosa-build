class MassBuild < ActiveRecord::Base
  belongs_to :platform
  belongs_to :user
  has_many :build_lists, :dependent => :destroy

  scope :by_platform, lambda { |platform| where(:platform_id => platform.id) }

  attr_accessor :repositories, :arches

  validates :platform_id, :arch_names, :name, :user_id, :repositories, :presence => true
  validates_inclusion_of :auto_publish, :in => [true, false]

  after_create :build_all

  def initialize(args = nil)
    super

    if new_record?
      rep_names = Repository.where(:id => self.repositories).map(&:name).join(", ")
      self.name = "#{Date.today.strftime("%d.%b")}-#{platform.name}(#{rep_names})"
      self.arch_names = Arch.where(:id => self.arches).map(&:name).join(", ")
    end
  end

  # ATTENTION: repositories and arches must be set before calling this method!
  def build_all
    platform.delay.build_all(
      :mass_build_id => self.id,
      :user => self.user,
      :repositories => self.repositories,
      :arches => self.arches,
      :auto_publish => self.auto_publish
    )
  end
end
