mass_builds = @mass_builds.map do |mass_build|
  [
    mass_build.id,

    link_to_mass_build(mass_build),

    mass_build.description,

    mass_build.created_at.to_s,

    link_to(t('layout.show'), platform_mass_build_path(@platform, mass_build.id))
  ]
end

json.sEcho                  params[:sEcho].to_i || -1
json.iTotalRecords          @total_mass_builds
json.iTotalDisplayRecords   @mass_builds.count
json.aaData                 mass_builds || []
