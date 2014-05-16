class Platforms::ContentsController < Platforms::BaseController
  include PaginateHelper

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user! if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :platform
  
  def index
    @path = params[:path].to_s
    @term = params[:term]

    respond_to do |format|
      format.html
      format.json do
        @contents = PlatformContent.find_by_platform(@platform, @path, @term)
                                   .paginate(paginate_params)
      end
    end
    
  end

  def destroy

  end

end
