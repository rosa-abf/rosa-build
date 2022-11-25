class Api::V1::TokensController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :load_platform_by_name_or_id, only: %i(index create)
  before_action :load_token, except: %i(index create hidden_platforms allowed)

  def index
    authorize :token_api
    tokens = @platform.tokens
    tokens = tokens.where("description like ?", "%#{params[:description]}%") if params[:description].present?
    tokens = tokens.find_each.map { |token| token_json(token) }.sort_by { |x| -x[:created_at] }
    render json: tokens
  end

  def allowed
    authorize :token_api
    head :ok
  end

  def show
    authorize :token_api
    render json: token_json(@token)
  end

  def create
    authorize :token_api
    token = @platform.tokens.build(token_params)
    token.creator = current_user
    if token.save
      render json: token_json(token)
    else
      render_validation_error token, "Failed to create token"
    end
  end

  def update
    authorize :token_api
    if @token.update_attributes(subject_params(@token.class, @token))
      render json: token_json(@token)
    else
      render_validation_error @token, "Token has not been updated"
    end
  end

  def destroy
    authorize :token_api
    @token.destroy
    render_json_response @token, "Token has been destroyed successfully"
  end

  def activate
    authorize :token_api
    if @token.unblock
      @token.updater = current_user
      @token.save
      render json: token_json(@token)
    else
      render_json_response @token, "Failed to reactivate token", 422
    end
  end

  def deactivate
    authorize :token_api
    if @token.block
      @token.updater = current_user
      @token.save
      render json: token_json(@token)
    else
      render_json_response @token, "Failed to deactivate token", 422
    end
  end

  def hidden_platforms
    authorize :token_api
    render json: {
      platforms: Platform.main.where(visibility: Platform::VISIBILITY_HIDDEN).pluck(:name)
    }
  end

  private

  def token_params
    subject_params(Token)
  end

  def token_json(token)
    res = %i(id description created_at status authentication_token).each.with_object({}) do |key, res|
      if key == :created_at
        res[key] = token.send(key).to_i
      else
        res[key] = token.send(key)
      end
    end
    res[:platform] = token.subject.name
    res[:url] = "#{APP_CONFIG['downloads_url']}/#{token.subject.name}/".gsub(/^(https?):\/\//, "\\1://#{res[:authentication_token]}@")
    res
  end

  def load_platform_by_name_or_id
    @platform = Platform.find_by(name: params[:platform]) || Platform.find_by(id: params[:platform])
    raise ActiveRecord::RecordNotFound if !@platform
  end

  def load_token
    @token = Token.find(params[:id])
  end
end
