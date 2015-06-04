module UsersHelper

  def avatar_url_by_email(email, size = :small)
    avatar_url(User.where(email: email).first || User.new(email: email), size)
  end

  def avatar_url(subject, size = :small)
    if subject.try('avatar?')
      subject.avatar.url(size)
    elsif subject.kind_of? Group
      'ava-big.png'
    else
      gravatar_url(subject.email, User::AVATAR_SIZES[size])
    end
  end

  def gravatar_url(email, size = 30)
    hex = email.present? ? Digest::MD5.hexdigest(email.try :downcase) : ''
    "https://secure.gravatar.com/avatar/#{}?s=#{size}&r=pg"
  end
end
