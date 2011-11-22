Factory.define(:build_list) do |p|
  p.association :project, :factory => :project
  p.association :pl, :factory => :platform
  p.association :arch, :factory => :arch
  p.bpl { |bl| bl.pl }
  p.project_version "1.0"
  p.build_requires true
  p.update_type 'security'
end