require 'spec_helper'

describe AdvisoriesController, type: :controller do
  context 'for all' do
    it "should be able to perform search action" do
      get :search
      expect(response).to_not redirect_to(forbidden_path)
    end

    it "should be able to perform index action" do
      get :index
      expect(response).to be_success
    end
  end
end
