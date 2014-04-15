module ActiveAdmin::AdminHelper

  include ActiveAdmin::Views

  def admin_polymorphic_path(resource)
    self.send("admin_#{resource.class.to_s.underscore}_path", resource)
  end

end

