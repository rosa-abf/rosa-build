module MassBuildHelper
  def link_to_list platform, mass_build, which
    link_to t("layout.mass_builds.#{which}"),
      get_list_platform_mass_build_path(@platform, mass_build, kind: which, format: :txt),
      target: "_blank" if can?(:get_list, mass_build)
  end
end
