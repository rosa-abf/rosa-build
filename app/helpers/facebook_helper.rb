module FacebookHelper

  # Returns a facebook-specific image for the current page.
  def facebook_meta_image
    resource         = get_resource
    @fb_meta_image ||= avatar_url(resource, :big) if resource.respond_to?(:avatar)
    @fb_meta_image ||= asset_url('fb-image.png')

    @fb_meta_image
  end

  # Returns a facebook-specific URL for the current page.
  def facebook_meta_url
    @fb_meta_url ||= fb_like_url(get_resource)
  end

  # Returns the facebook application id.
  def facebook_meta_app_id
    APP_CONFIG['keys']['facebook']['id']
  end

  # Returns the facebook site name - used for the site:og_name meta tag.
  def facebook_site_name
    APP_CONFIG['project_name']
  end

  # Creates a 'like' URL for the given object instance.
  def fb_like_url(object=nil)
    # All likes for resources go to referrers#like, which redirects them
    # to the appropriate target.
    begin
      # Make sure we're using the correct domain. This should happen automatically,
      # but is a bit flaky in cucumber so set it explicitly to be safe.
      #domain = current_site.present? ? current_site.domain : request.host
      url = object.respond_to?(:fb_like_url) ?
        object.fb_like_url : polymorphic_url(object)#, host: domain)
    rescue
    end if object
    url ||= request.url
    # Clean up unnecessary params
    url.gsub!(/\?.*/, '')
    url << "?page=#{params[:page]}" if params[:page].to_i > 1
    url
  end

  protected

    # Gets the current resource.
    def get_resource
      case controller
      when Groups::BaseController
        @group
      when Users::BaseController
        @user
      when Projects::Git::BaseController
        @project
      else
        instance_variable_get "@#{controller_name.singularize}"
      end
    end

end
