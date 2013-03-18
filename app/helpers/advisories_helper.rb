module AdvisoriesHelper
  def advisories_select_options(advisories, opts = {:class => 'popoverable'})
    def_values = [[t("layout.advisories.no_"), 'no'], [t("layout.advisories.new"), 'new'], [t("layout.advisories.existing"), 'existing', {:class => 'advisory_id'}]]
    options_for_select(def_values, def_values.first)
  end

  def advisory_id_for_hint
    sprintf(Advisory::ID_STRING_TEMPLATE, :type => "{#{Advisory::TYPES.values.join(',')}}",
                                          :year => 'YYYY', :id => 'XXXX')
  end

  def construct_ref_link(ref)
    ref = sanitize(ref)
    url = if ref =~ %r[^http(s?)://*]
      ref
    else
      'http://' << ref
    end
    link_to url, url
  end
end
