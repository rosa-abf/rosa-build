module PlatformsHelper

  def repository_name_postfix(platform)
     return "" unless platform
     return platform.released ? '/update' : '/release'
  end

  def platform_printed_name(platform)
    return "" unless platform
    platform.released? ? "#{platform.name} #{I18n.t("layout.platforms.released_suffix")}" : platform.name
  end

  def platform_arch_settings(platform)
    settings  = platform.platform_arch_settings
    arches    = if (arch_ids = settings.map(&:arch_id)) && arch_ids.present?
                  Arch.where('id not in (?)', arch_ids)
                else
                  Arch.all
                end
    settings |= arches.map do |arch|
      platform.platform_arch_settings.build(
        :arch_id      => arch.id,
        :time_living  => PlatformArchSetting::DEFAULT_TIME_LIVING
      )
    end
    settings.sort_by{ |s| s.arch.name }
  end

  def fa_platform_visibility_icon(platform)
    return nil unless platform
    image, color = platform.hidden? ? ['lock', 'text-danger fa-fw']: ['unlock-alt', 'text-success fa-fw']
    fa_icon(image, class: color)
  end
end
