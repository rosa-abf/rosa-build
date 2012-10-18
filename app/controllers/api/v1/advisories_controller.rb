# -*- encoding : utf-8 -*-
class Api::V1::AdvisoriesController < Api::V1::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index, :show] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource :advisory, :find_by => :advisory_id
  load_and_authorize_resource :build_list,
    :find_by => :build_list_id, :only => [:create, :update]

  def index
    @advisories = @advisories.scoped(:include => :platforms).
      paginate(paginate_params)
  end

  def show
    @packages_info = @advisory.fetch_packages_info
  end

  def create
    @advisory = @build_list.build_and_associate_advisory(params[:advisory])
    if @build_list.status == BuildList::BUILD_PUBLISHED &&
        @advisory.save && @build_list.save
      render_json_response @advisory, 'Advisory has been created successfully'
    else
      render_validation_error @advisory, error_message(@build_list, 'Advisory has not been created')
    end
  end

  def update
    if @build_list.status == BuildList::BUILD_PUBLISHED &&
        @advisory.attach_build_list(@build_list) &&
        @advisory.save && @build_list.save
      render_json_response @advisory, "Build list '#{@build_list.id}' has been attached to advisory successfully"
    else
      render_validation_error @advisory, error_message(@build_list, 'Build list has not been attached to advisory')
    end
  end

end
