class ActionController::Base

    def can_perform? target = :system
      c = self.controller_name
      a = self.action_name

      current_user.can_perform? c, a, target
    end

    def check_global_access
      unless can_perform?
        flash[:notice] = t('layout.not_access')
        if request.env['HTTP_REFERER']
          redirect_to(:back)
        else
          redirect_to(:root)
        end
      end
    end

    def rights_to target
      ActiveRecord::Base.rights_to target
    end

    def roles_to target
      ActiveRecord::Base.roles_to target
    end

end
