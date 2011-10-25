class ActionController::Base

    def can_perform? target = :system
      c = self.controller_name
      a = self.action_name

      current_user.can_perform? c, a, target
    end

    def check_global_rights
      unless can_perform?
        flash[:notice] = t('layout.not_access')
        redirect_to(:back)
      end
    end

    def rights_to target
      ActiveRecord::Base.rights_to target
    end

    def roles_to target
      ActiveRecord::Base.roles_to target
    end

end
