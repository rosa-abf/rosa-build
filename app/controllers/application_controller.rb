# coding: UTF-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  layout :layout_by_resource
  private
    def checkright(role_id)
      @role=Role.find(role_id)
      if @role.name.downcase!="admin"
        @c = self.controller_name
        @a = self.action_name
        case @c
          when "projects"
            case @a
              when "new", "show", "create"
                @right=1,2
              when "build", "process_build"
                @right=3
            end
          when "repositories"
            case @a
              when "show"
                @right=4
              when "add_project", "remove_project"
                @right=5
              when "new", "create"
                @right=6  
            end
          when "platforms"
            case @a
              when "edit", "update", "freeze", "unfreeze"
                @right=7
            end
          else return true
        end
        Permission.where(:role_id => @role.id, :right_id => @right).first
        @ok=false if @permission.nil?
        if not @ok
          flash[:notice] = t('layout.not_access')
          redirect_to(:back)
        end
      end
    end

  before_filter lambda { EventLog.current_controller = self }, :only => [:create, :destroy, :open_id] # :update
  after_filter lambda { EventLog.current_controller = nil }

  protected
    def layout_by_resource
      if devise_controller?
        "sessions"
      else
        "application"
      end
    end

    def authenticate_build_service!
      if request.remote_ip != APP_CONFIG['build_service_ip']
        render :nothing => true, :status => 403
      end
    end

    def authenticate_product_builder!
      if request.remote_ip != APP_CONFIG['product_builder_ip']
        render :nothing => true, :status => 403
      end
    end
end
