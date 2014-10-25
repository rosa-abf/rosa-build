platforms = Platform.main.opened.
  where(distrib_type: APP_CONFIG['distr_types'].first).order('name ASC')

json.list       @platform.urpmi_list(request.host)
json.platforms  platforms.pluck(:name)
json.arches     Arch.order('name ASC').pluck(:name)
