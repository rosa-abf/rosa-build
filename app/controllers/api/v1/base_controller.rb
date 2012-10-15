# -*- encoding : utf-8 -*-
class Api::V1::BaseController < ApplicationController
  #respond_to :json

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { render :json => {:message => t("flash.exception_message")}.to_json, :status => 403 }
    end
  end

  protected

  def add_member_to_subject(subject)
    class_name = subject.class.name.downcase
    if member.present? && subject.add_member(member)
      render_json_response subject, "#{member.class.to_s} '#{member.id}' has been added to #{class_name} successfully"
    else
      render_validation_error subject, "Member has not been added to #{class_name}"
    end
  end

  def remove_member_from_subject(subject)
    class_name = subject.class.name.downcase
    if member.present? && subject.remove_member(member)
      render_json_response subject, "#{member.class.to_s} '#{member.id}' has been removed from #{class_name} successfully"
    else
      render_validation_error subject, "Member has not been removed from #{class_name}"
    end
  end

  def destroy_subject(subject)
    subject.destroy # later with resque
    render_json_response subject, "#{subject.class.name} has been destroyed successfully"
  end

  def update_subject(subject)
    class_name = subject.class.name
    if subject.update_attributes(params[class_name.downcase.to_sym] || {})
      render_json_response subject, "#{class_name} has been updated successfully"
    else
      render_validation_error subject, "#{class_name} has not been updated"
    end
  end

  def paginate_params
    per_page = params[:per_page].to_i
    per_page = 20 if per_page < 1
    per_page = 100 if per_page >100
    {:page => params[:page], :per_page => per_page}
  end

  def render_json_response(subject, message, status = 200)
    id = status != 200 ? nil : subject.id

    render :json => {
      subject.class.name.downcase.to_sym => {
        :id => id,
        :message => message
      }
    }.to_json, :status => status
  end

  def render_validation_error(subject, message)
    errors = subject.errors.full_messages.join('. ')
    if errors.present?
      message << '. ' << errors
    end
    render_json_response(subject, message, 422)
  end

  private

  def member
    return @member if @member
    if params[:type] == 'User'
      member = User
    elsif params[:type] == 'Group'
      member = Group
    end
    @member = member.where(:id => params[:member_id]).first if member
    @member ||= ''
  end 

end
