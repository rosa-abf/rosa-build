class SitemapController < ApplicationController

  def show
    redirect_to "/sitemaps/#{request.host_with_port.gsub(/www./, '')}/sitemap.xml.gz"
  end

  def robots
    render file: 'sitemap/robots', layout: false, content_type: Mime::TEXT
  end

end