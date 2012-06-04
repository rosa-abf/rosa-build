# -*- encoding : utf-8 -*-
module AdvisoriesHelper
  def advisories_select_options(advisories, opts = {:class => 'popoverable'})
    def_values = [[t("layout.advisories.no_"), 'no'], [t("layout.advisories.new"), 'new']]
    options_for_select(def_values, def_values.first) +
    options_for_select(advisories.map { |a| [a.advisory_id, :class => "#{opts[:class]} #{a.update_type}"] })
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
