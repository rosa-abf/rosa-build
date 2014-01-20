module Preregistration
  module Devise
    module RegistrationsController
      extend ActiveSupport::Concern

      included do
        alias_method_chain :create, :token
        alias_method_chain :new, :token
      end

      def new_with_token
        if params['invitation_token']
          req = RegisterRequest.approved.where(:token => params['invitation_token'].strip).first
          redirect_to new_register_request_path and return unless req

          resource = build_resource({})
          resource.name  = req.name  if resource.respond_to? :name
          resource.email = req.email if resource.respond_to? :email
          @invitation_token = req.token

          respond_with_navigational(resource){ render :new }
        else
          redirect_to new_register_request_path
        end
      end

      def create_with_token
        redirect_to new_register_request_path and return unless params['invitation_token']
        req = RegisterRequest.approved.where(:token => params['invitation_token'].strip).first

        build_resource

        redirect_to new_register_request_path and return unless req and resource.email == req.email

        @invitation_token = req.token
        resource.skip_confirmation!
        if resource.save
          if resource.active_for_authentication?
            set_flash_message :notice, :signed_up if is_navigational_format?
            sign_in(resource_name, resource)
            respond_with resource, :location => after_sign_up_path_for(resource)
          else
            set_flash_message :notice, :inactive_signed_up, :reason => inactive_reason(resource) if is_navigational_format?
            expire_session_data_after_sign_in!
            respond_with resource, :location => after_inactive_sign_up_path_for(resource)
          end
        else
          clean_up_passwords(resource)
          respond_with_navigational(resource) { render :new }
        end
      end

    end # RegistrationsController
  end # Devise
end # Preregistration

Rails.application.config.to_prepare do
  ::Devise::RegistrationsController.send :include, Preregistration::Devise::RegistrationsController if APP_CONFIG['preregistration']
end
