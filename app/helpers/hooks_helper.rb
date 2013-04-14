module HooksHelper

  def web_fields
    {:url => :string}
  end

  def hipchat_fields
    {
      :auth_token => :string,
      :room => :string,
      :restrict_to_branch => :string,
      :notify => :boolean
    }
  end

end
