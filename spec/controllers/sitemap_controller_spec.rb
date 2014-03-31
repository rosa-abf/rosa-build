require 'spec_helper'

describe SitemapController do
  describe 'robots' do

    it 'is successful' do
      get :robots
      response.should be_success
      response.should render_template('sitemap/robots')
    end

    context 'validate robots.txt' do
      render_views

      it 'ensures that Host is correct' do
        get :robots
        response.body.should match(/^Host: http:\/\/test.host$/)
      end

      it 'ensures that Sitemap is correct' do
        get :robots
        response.body.should match(/^Sitemap: http:\/\/test.host\/sitemap.xml.gz$/)
      end
    end
  end

  describe 'show' do

    it 'is successful' do
      get :show
      response.should redirect_to("/sitemaps/test.host/sitemap.xml.gz")
    end

  end

end
