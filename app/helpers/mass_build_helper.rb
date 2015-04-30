module MassBuildHelper

  def link_to_list platform, mass_build, which
    link_to t("layout.mass_builds.#{which}"),
      get_list_platform_mass_build_path(platform, mass_build, kind: which, format: :txt),
      target: "_blank" if policy(mass_build).get_list?
  end

  def link_to_mass_build(mass_build)
    link_to mass_build.name, build_lists_path+"#?#{{filter: {mass_build_id: mass_build.id, ownership: 'everything'}}.to_param}"
  end

  def new_mass_build_data(mass_build, platform, params)
    {
      platform_id:  mass_build.save_to_platform.try(:id),
      repositories: platform.repositories.map do |repo|
                      { id:      repo.id,
                        name:    repo.name,
                        checked: (params[:repositories]||[]).include?(repo.id.to_s) }
                    end

    }.to_json
  end

end
