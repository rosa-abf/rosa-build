module FacebookHelper

  # Returns a facebook-specific title for the current page.
  def facebook_meta_title
    resource         = get_resource
    @fb_meta_title ||= resource.fb_meta_title if resource.respond_to?(:fb_meta_title)
    @fb_meta_title   = APP_CONFIG['project_name'] if @fb_meta_title.blank?
    @fb_meta_title
  end

  # Returns a facebook-specific description for the current page.
  def facebook_meta_description
    resource               = get_resource
    @fb_meta_description ||= resource.fb_meta_description if resource.respond_to?(:fb_meta_description)
    @fb_meta_description ||= resource.description if resource.respond_to?(:description)
    @fb_meta_description   = I18n.t('helpers.facebook.meta_description') if @fb_meta_description.blank?
    truncate(@fb_meta_description, length: 255)
  end

  # Returns a facebook-specific image for the current page.
  def facebook_meta_image
    resource         = get_resource
    @fb_meta_image ||= avatar_url(resource, :big) if resource.respond_to?(:avatar)
    @fb_meta_image ||= asset_url('logo-mini.png')

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

    # Hack to check if a translation is defined for a particular key.
    def translation_defined?(key)
      I18n.backend.exists?(:en, key)
    end

end
