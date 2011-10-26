class Role < ActiveRecord::Base
  has_many :permissions
  has_many :rights, :through => :permissions
  has_many :relations, :through => :role_lines

  serialize :can_see, Hash

  validate :name, :presence => true

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
      rescue
        new
      end
      new
      a.rights = []
      a.attributes = fields
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
