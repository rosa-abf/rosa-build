class Api::V1::ChainBuildsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :load_chain_build, except: %i[last]

  def show
    render json: {
      chain_build: {
        id: @chain_build.id,
        arches: @chain_build.arches.pluck(:name)
      }
    }, status: 200
  end

  def last
    chain_build = ChainBuild.for_user(current_user).last
    unless chain_build
      render json: {
        chain_build: nil
      }, status: 404
      return
    end
    authorize chain_build
    render json: {
      chain_build: {
        id: chain_build.id,
        arches: chain_build.arches.pluck(:name)
      }
    }, status: 200
  end

  private

  def load_chain_build
    @chain_build = ChainBuild.for_user(current_user).find(params[:id])
    authorize @chain_build
  end
end