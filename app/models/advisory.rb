class Advisory < ActiveRecord::Base
  has_and_belongs_to_many :platforms
  has_many :build_lists
  belongs_to :project

  validates :description, :update_type, :presence => true

  after_create :generate_advisory_id
  before_save  :normalize_references, :if => :references_changed?

  ID_TEMPLATE = 'ROSA-%<type>s-%<year>d:%<id>04d'
  TYPES = {'security' => 'SA', 'bugfix' => 'A'}

  scope :by_project, lambda {|p| where('project_id' => p.try(:id) || p)}

  def to_param
    advisory_id
  end

  protected

  def generate_advisory_id
    self.advisory_id = sprintf(ID_TEMPLATE, :type => TYPES[self.update_type], :year => Time.now.utc.year, :id => self.id)
    self.save
  end

  def normalize_references
    self.references.gsub!(/\r| /, '')
    self.references = self.references.split('\n').map do |ref|
      ref = CGI::escapeHTML(ref)
      ref = "http://#{ref}" unless ref =~ %r[^http(s?)://*]
      ref
    end.join("\n")
  end

end
Advisory.include_root_in_json = false
