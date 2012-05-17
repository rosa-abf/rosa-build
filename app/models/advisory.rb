class Advisory < ActiveRecord::Base
  has_and_belongs_to_many :platforms
  has_many :build_lists
  belongs_to :project

  validates :description, :update_type, :presence => true

  after_create :generate_advisory_id

  ID_TEMPLATE = 'ROSA-%<type>s-%<year>d:%<id>04d'
  TYPES = {'security' => 'SA', 'bugfix' => 'A'}

  def to_param
    advisory_id
  end

  protected

  def generate_advisory_id
    self.advisory_id = sprintf(ID_TEMPLATE, :type => TYPES[self.update_type], :year => Time.now.utc.year, :id => self.id)
    self.save
  end
end
