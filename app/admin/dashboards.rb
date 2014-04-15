ActiveAdmin.register_page 'Dashboard' do

  menu priority: 1

  content do

    columns do
      column do
        panel "Deploy Information" do
          require 'deploy_info'

          abf = "https://abf.io/abf/rosa-build/"
          #jenkins = "https://ci.shuttlerock.com/"

          attributes_table_for DeployInfo do
            row('Branch')       { link_to DeployInfo::BRANCH, "#{abf}tree/#{DeployInfo::BRANCH}" }
            row('Commit')       { link_to DeployInfo::GIT_COMMIT, "#{abf}commit/#{DeployInfo::GIT_COMMIT}" }
            row('Build Number') { DeployInfo::BUILD_NUMBER }
            row('Build ID')     { DeployInfo::BUILD_ID }
            row('Deployer')     { DeployInfo::DEPLOYER }
            row(:message)       { pre DeployInfo.message }
          end
        end # panel
      end # column
    end # columns


  end # content

end
