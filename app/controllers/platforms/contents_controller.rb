class Platforms::ContentsController < Platforms::BaseController
  include PaginateHelper

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: :index if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :platform

  def index
    respond_to do |format|
      format.html
      format.json do
        @path = params[:path].to_s
        @term     = params[:term]

        @contents = PlatformContent.find_by_platform(@platform, @path, @term)
        @total_items = @contents.count
        @contents = @contents.paginate(paginate_params)
      end
    end

  end

  def remove_file
    authorize!(:remove_file, @platform)
    PlatformContent.remove_file(@platform, params[:path])
    render nothing: true
  end

end
