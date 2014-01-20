class AutocompletesController < ApplicationController
  before_filter :authenticate_user!

  autocomplete :group,  :uname
  autocomplete :user,   :uname

  def autocomplete_extra_build_list
    bl = BuildList.for_extra_build_lists(params[:term], current_ability, save_to_platform).first
    results << {  :id     => bl.id,
                  :value  => bl.id,
                  :label  => "#{bl.id} (#{bl.project.name} - #{bl.arch.name})",
                  :path   => build_list_path(bl)
                } if bl
    render json: results.to_json
  end

  def autocomplete_extra_repositories
    # Only personal and build for platform repositories can be attached to the build
    Platform.includes(:repositories).search(params[:term]).search_order
            .accessible_by(current_ability, :read).limit(5)
            .where("platforms.platform_type = 'personal' OR platforms.id = ?",
                    params[:build_for_platform_id].to_i).each do |platform|
      platform.repositories.each do |repository|
        label = "#{platform.name}/#{repository.name}"
        results <<  { :id     => repository.id,
                      :label  => label,
                      :value  => label,
                      :path   => platform_repository_path(platform, repository)
                    }
      end
    end if save_to_platform.personal?
    render json: results.to_json
  end

  protected

  def save_to_platform
    @save_to_platform ||= Platform.find(params[:platform_id])
  end

  def results
    @results ||= []
  end

end
