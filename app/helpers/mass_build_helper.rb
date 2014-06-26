module MassBuildHelper
  def link_to_list platform, mass_build, which
    link_to t("layout.mass_builds.#{which}"),
      get_list_platform_mass_build_path(@platform, mass_build, kind: which, format: :txt),
      target: "_blank" if can?(:get_list, mass_build)
  end

  def link_to_mass_build(mass_build)
    link_to mass_build.name, build_lists_path+"#?#{{filter: {mass_build_id: mass_build.id, ownership: 'everything'}}.to_param}"
  end
end
