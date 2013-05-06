class ReservedNameValidator < ActiveModel::EachValidator
  RESERVED_NAMES = %w{
    about account add admin administrator api autocomplete_group_uname
    app apps archive archives auth
    blog
    config connect contact create commit commits
    dashboard delete direct_messages download downloads
    edit email
    faq favorites feed feeds follow followers following
    help home
    invitations invite
    jobs
    login log-in log_in logout log-out log_out logs
    map maps
    new none
    oauth oauth_clients openid
    privacy
    register remove replies rss root
    save search sessions settings
    signup sign-up sign_up signin sign-in sign_in signout sign-out sign_out
    sitemap ssl subscribe
    teams terms test tour trends tree
    unfollow unsubscribe upload uploads url user
    widget widgets wiki
    xfn xmpp
  }

  def reserved_names
    @reserved_names ||= RESERVED_NAMES +
                        Rails.application.routes.routes.map{|r| r.path.spec.to_s.match(/^\/([\w-]+)/)[1] rescue nil}.uniq.compact # current routes
  end

  def validate_each(record, attribute, value)
    if reserved_names.include?(value.to_s.downcase)
      record.errors.add(attribute, :exclusion, options.merge(:value => value))
    end
  end
end
