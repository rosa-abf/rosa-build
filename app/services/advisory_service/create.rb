module AdvisoryService::Create
  def self.call(opts = {})
    advisory_params = opts[:advisory_params]
    projects = opts[:projects]
    advisory = Advisory.new(advisory_params)
    return {
      success: false,
      advisory: advisory
    } if !advisory.valid?
    parsed = parse_projects_platforms(advisory, projects)
    return {
      success: false,
      advisory: advisory
    } if !advisory.errors.empty?
    parsed.keys.each do |platform_id|
      parsed[platform_id].each do |project_id|
        advisory.advisory_items << AdvisoryItem.new(
          project_id: project_id,
          platform_id: platform_id
        )
      end
    end
    advisory.save
    {
      success: true,
      advisory: advisory
    }
  end

  def self.parse_projects_platforms(advisory, pr)
    pr ||= {}
    if !pr.is_a?(Hash)
      advisory.errors.add(:base, "Projects is not a hash")
      return {}
    end
    if pr.empty?
      advisory.errors.add(:base, 'No projects provided')
      return {}
    end
    res = {}
    pr.keys.each do |pl|
      platform = if pl.to_i != 0
        Platform.find_by_id(pl)
      else
        Platform.find_by_name(pl)
      end
      if !platform
        advisory.errors.add(:base, "No such platform with id/name #{pl}")
      elsif !platform.main?
        advisory.errors.add(:base, "Platform #{platform.name} is not a main platform")
      else
        next if !pr[pl].is_a?(Array) || pr[pl].empty?
        lowered = pr[pl].map(&:to_s).map(&:strip).select(&:present?).map(&:downcase).uniq
        projects_ids = platform.projects.where(
          'lower(concat(owner_uname, \'/\', projects.name)) IN (?)',
          lowered
        ).
        pluck(:owner_uname, 'projects.name', 'projects.id').map { |x| 
          ["#{x[0].downcase}/#{x[1].downcase}", x[2]] 
        }
        project_names = projects_ids.map(&:first)
        missing_projects = lowered - project_names
        if !missing_projects.empty?
          advisory.errors.add(:base, "No such projects in platform #{platform.name}: #{missing_projects.join(', ')}")
        else
          res[platform.id] = projects_ids.map(&:second)
        end
      end
    end
    res
  end
end
