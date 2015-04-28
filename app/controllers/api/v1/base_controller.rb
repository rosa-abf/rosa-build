class Api::V1::BaseController < ApplicationController
  include PaginateHelper
  respond_to :json

  helper_method :member_path

  rescue_from Pundit::NotAuthorizedError do |exception|
    respond_to do |format|
      format.json { render json: {message: t('flash.exception_message')}.to_json, status: 403 }
      format.csv  { render text: t('flash.exception_message'), status: 403 }
    end
  end

  protected

  def set_csv_file_headers(file_name)
    headers['Content-Type'] = 'text/csv'
    headers['Content-disposition'] = "attachment; filename=\"#{file_name}.csv\""
  end

  def set_streaming_headers
    # nginx doc: Setting this to "no" will allow unbuffered responses suitable for Comet and HTTP streaming applications
    headers['X-Accel-Buffering'] = 'no'

    headers['Cache-Control'] ||= 'no-cache'
    headers.delete 'Content-Length'
  end

  def set_locale
    I18n.locale = :en
  end

  def error_message(subject, message)
    [message, subject.errors.full_messages].flatten.join('. ')
  end

  def create_subject(subject)
    authorize subject, :create?
    class_name = subject.class.name
    if subject.save
      render_json_response subject, "#{class_name} has been created successfully"
    else
      render_validation_error subject, "#{class_name} has not been created"
    end
  end

  def update_member_in_subject(subject, relation = :relations)
    authorize subject, :update_member?
    role = params[:role]
    class_name = subject.class.name.downcase
    if member.present? && role.present? && subject.respond_to?(:owner) && subject.owner != member &&
      subject.send(relation).by_actor(member).update_all(role: role)
      render_json_response subject, "Role for #{member.class.name.downcase} '#{member.id} has been updated in #{class_name} successfully"
    else
      render_validation_error subject, "Role for member has not been updated in #{class_name}"
    end
  end

  def add_member_to_subject(subject, role = 'admin')
    authorize subject, :add_member?
    class_name = subject.class.name.downcase
    if member.present? && subject.add_member(member, role)
      render_json_response subject, "#{member.class.to_s} '#{member.id}' has been added to #{class_name} successfully"
    else
      render_validation_error subject, "Member has not been added to #{class_name}"
    end
  end

  def remove_member_from_subject(subject)
    authorize subject, :remove_member?
    class_name = subject.class.name.downcase
    if member.present? && subject.remove_member(member)
      render_json_response subject, "#{member.class.to_s} '#{member.id}' has been removed from #{class_name} successfully"
    else
      render_validation_error subject, "Member has not been removed from #{class_name}"
    end
  end

  def destroy_subject(subject)
    authorize subject, :destroy?
    subject.destroy # later with resque
    render_json_response subject, "#{subject.class.name} has been destroyed successfully"
  end

  def update_subject(subject)
    authorize subject, :update?
    class_name = subject.class.name
    if subject.update_attributes(subject_params(subject.class, subject))
      render_json_response subject, "#{class_name} has been updated successfully"
    else
      render_validation_error subject, "#{class_name} has not been updated"
    end
  end

  def render_json_response(subject, message, status = 200)
    id = status != 200 ? nil : subject.id

    render json: {
      subject.class.name.underscore.to_sym => {
        id: id,
        message: message
      }
    }, status: status
  end

  def render_validation_error(subject, message)
    render_json_response(subject, error_message(subject, message), 422)
  end

  def member_path(subject)
    if subject.is_a?(User)
      api_v1_user_path(subject.id, format: :json)
    else
      api_v1_group_path(subject.id, format: :json)
    end
  end

  private

  def member
    if @member.blank? && %w(User Group).include?(params[:type])
      @member = params[:type].constantize.where(id: params[:member_id]).first
    end
    @member
  end

end
