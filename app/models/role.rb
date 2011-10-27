class Role < ActiveRecord::Base
  has_many :permissions
  has_many :rights, :through => :permissions
  has_many :relations, :through => :role_lines

  serialize :can_see, Hash

  validate :name, :presence => true

  scope :exclude_acter, lambda {|obj| {:conditions => (obj != :all and obj != '') ? ['"to" <> ?', obj.to_s] : '"to" NOT NULL OR "to" <> \'\''}}
  scope :exclude_target, lambda {|targ| {:conditions => (targ != :system and targ != '') ? ['"on" <> ?', targ.to_s] : '"on" NOT NULL OR "to" <> \'\''}}

  scope :by_acter, lambda {|obj| {:conditions => (obj != :all and obj != '') ? ['"to" = ?', obj.to_s] : '"to" ISNULL OR "to" = \'\''}}
  scope :by_target, lambda {|targ| {:conditions => (targ != :system and targ != '') ? ['"on" = ?', targ.to_s] : '"on" ISNULL OR "on" = \'\''}}

  scope :default, where(:use_default => true)

  before_save :check_default, :check_owner_default

  def to_dump
    tmp = attributes.reject {|k,v| ['created_at', 'updated_at'].include? k}
    tmp['rights'] = rights.inject({}) do |h, right|
      h[right.controller] ||= []
      h[right.controller] << right.action
      h[right.controller].uniq!
      h
    end
    return tmp
  end

  protected

    def check_default
      if on_changed? and !on || on == ''
        roles = Role.by_acter(to).by_target('').default
        puts roles.inspect
        if roles and roles.size > 0
          roles.each {|r| r.update_attributes(:use_default => false)}
        end
      end
      true
    end

    def check_owner_default
      self[:use_default_for_owner] = false if use_default_for_owner and (to.nil? || to == '')
      true
    end

  class << self

    def save_dump filename = 'config/roles.yml'
      fn = File.expand_path filename
      File.open(fn, 'w'){|f| f.puts dump_roles}
      return filename
    end

    def dump_roles
      roles = Role.find(:all, :include => :rights)
      roles = roles.map(&:to_dump)
      return {:Roles => roles}.to_yaml
    end


    def all_from_dump! dump_hash
      arr = []
      dump_hash[:Roles].each do |role|
        arr << from_dump!(role)
      end
      arr
    end

    def all_from_dump dump_hash
      arr = []
      dump_hash[:Roles].each do |role|
        arr << from_dump(role)
      end
      arr
    end

    def from_dump! fields
      from_dump(fields).save
    end

    def from_dump fields
      rights = fields.delete('rights')
      a = begin
        find(fields['id'])
      rescue ActiveRecord::RecordNotFound
        new
      end
      a.rights = []
      a.attributes = fields
      Permission.delete_all(:conditions => ['role_id = ?', a.id])
      rights.each do |con, acts|
        acts.each do |act|
          unless r = Right.where(:controller => con, :action => act)
            r = Right.create(:controller => con, :action => act)
          end
          a.rights << r
        end
      end
      return a
    end
  end
end
