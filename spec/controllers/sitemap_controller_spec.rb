require 'spec_helper'

describe SitemapController, type: :controller do
  describe 'robots' do

    it 'is successful' do
      get :robots
      expect(response).to be_success
      expect(response).to render_template('sitemap/robots')
    end

    context 'validate robots.txt' do
      render_views

      it 'ensures that Host is correct' do
        get :robots
        expect(response.body).to match(/^Host: http:\/\/test.host$/)
      end

      it 'ensures that Sitemap is correct' do
        get :robots
        expect(response.body).to match(/^Sitemap: http:\/\/test.host\/sitemap.xml.gz$/)
      end
    end
  end

  describe 'show' do

    it 'is successful' do
      get :show
      expect(response).to redirect_to("/sitemaps/test.host/sitemap.xml.gz")
    end

  end

end
