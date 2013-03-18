module PlatformsHelper
  def repository_name_postfix(platform)
     return "" unless platform
     return platform.released ? '/update' : '/release'
  end

  def platform_printed_name(platform)
    return "" unless platform
    platform.released? ? "#{platform.name} #{I18n.t("layout.platforms.released_suffix")}" : platform.name
  end

end
