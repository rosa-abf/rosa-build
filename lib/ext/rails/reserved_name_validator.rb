class ReservedNameValidator < ActiveModel::EachValidator
  RESERVED_NAMES = %w{
    about account add admin administrator api
    app apps archive archives auth
    blog
    config connect contact create commit commits 
    dashboard delete direct_messages downloads
    edit email
    faq favorites feed feeds follow followers following
    help home
    invitations invite
    jobs
    login log-in log_in logout log-out log_out logs
    map maps
    oauth oauth_clients openid
    privacy
    register remove replies rss root
    save search sessions settings
    signup sign-up sign_up signin sign-in sign_in signout sign-out sign_out
    sitemap ssl subscribe
    teams terms test trends tree
    unfollow unsubscribe url user
    widget widgets wiki
    xfn xmpp
  } << Rails.application.routes.routes.map{|r| r.path.spec.to_s.match(/^\/([\w-]+)/)[1] rescue nil}.uniq.compact # current routes

  def validate_each(record, attribute, value)
    if RESERVED_NAMES.include?(value.downcase)
      record.errors.add(attribute, :exclusion, options.merge!(:value => value))
    end
  end
end
