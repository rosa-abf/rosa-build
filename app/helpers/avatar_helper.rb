module AvatarHelper
  def update_avatar(subject, params)
    if subject.avatar && params[:delete_avatar] == '1'
      subject.avatar = nil
      subject.save
    end
  end
end