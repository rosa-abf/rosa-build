# -*- encoding : utf-8 -*-
module AdvisoriesHelper
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
