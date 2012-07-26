class CountersLog < ActiveRecord::Base
  belongs_to :build_list
  belongs_to :mass_build
end
