class Advisory < ActiveRecord::Base
  self.include_root_in_json = false
  self.per_page             = 30

  TYPES = {'security' => 'SA', 'bug' => 'A'}

  has_many :advisory_items, dependent: :destroy

  validates :description, :update_type, presence: true
  validates :update_type, inclusion: TYPES.keys

  before_save  :regenerate_advisory_id, if: ->(a) { a.persisted? && a.update_type_changed? }
  before_save  :normalize_references, if: :references_changed?
  after_create :generate_advisory_id

  ID_TEMPLATE        = 'ROSA-%<type>s-%<year>d-%<id>04d'
  ID_STRING_TEMPLATE = 'ROSA-%<type>s-%<year>04s-%<id>04s'

  scope :search, ->(q) {
    q = q.to_s.strip
    where("#{table_name}.advisory_id ILIKE :q OR #{table_name}.description ILIKE :q", q: "%#{q}%") if q.present?
  }
  scope :search_by_id,   ->(aid) { where("#{table_name}.advisory_id ILIKE ?", "%#{aid.to_s.strip}%") }
  scope :by_update_type, ->(ut) { where(update_type: ut) }
  default_scope { order(created_at: :desc) }

  def to_param
    advisory_id
  end

  def platforms
    Platform.where(id: advisory_items.pluck('DISTINCT platform_id'))
  end

  def projects
    Project.where(id: advisory_items.pluck('DISTINCT project_id'))
  end

  def fetch_platforms_projects
    res = {}
    advisory_items.find_each do |item|
      res[item.platform_id] ||= []
      res[item.platform_id] << item.project_id
    end
    res
  end

  protected

  def generate_advisory_id
    self.advisory_id = get_advisory_id
    self.save
  end

  def regenerate_advisory_id
    self.advisory_id = get_advisory_id
  end

  def get_advisory_id
    sprintf(ID_TEMPLATE, type: TYPES[self.update_type], year: Time.now.utc.year, id: self.id)
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
