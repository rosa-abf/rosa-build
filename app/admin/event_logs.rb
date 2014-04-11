ActiveAdmin.register EventLog do

  menu parent: 'Misc'

  actions :all, except: %i(create update new edit destroy)

  controller do
    def scoped_collection
      EventLog.includes(:user)
    end
  end

  index do
    column :id
    column :kind
    column :created_at
    column :user
    column :ip
    column :protocol
    column('Description') do |el|
      msg = %w([)
      msg << I18n.t("event_log.controllers.#{el.controller.underscore}", default: el.controller) << "]"
      msg << I18n.t("event_log.actions.#{el.controller.underscore}.#{el.action}", default: :"event_log.actions.#{el.action}")
      if el.eventable_id.present? and el.eventable_type.present?
        msg << '' << I18n.t("activerecord.models.#{el.eventable_type.underscore}")
        msg << el.eventable_name
        msg << "(id##{el.eventable_id})" # link_to "id##{el.eventable_id}", el.eventable
      end
      msg << el.message.to_s
      msg.join(' ')
    end


    default_actions
  end

end
