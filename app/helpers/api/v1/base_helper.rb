module Api::V1::BaseHelper

  protected

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