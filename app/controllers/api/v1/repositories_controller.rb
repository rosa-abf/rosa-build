class Api::V1::RepositoriesController < Api::V1::BaseController
  respond_to :csv, only: :packages

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:show, :projects] if APP_CONFIG['anonymous_access']
  before_action :load_repository

  def show
  end

  def projects
    @projects = @repository.projects.recent.paginate(paginate_params)
  end

  def update
    update_subject @repository
  end

  def add_member
    add_member_to_subject @repository
  end

  def remove_member
    remove_member_from_subject @repository
  end

  def destroy
    destroy_subject @repository
  end

  def key_pair
  end

  # Only one request per 15 minutes for each platform
  def packages
    key, now = [@repository.platform.id, :repository_packages], Time.zone.now
    last_request = Rails.cache.read(key)
    if last_request.present? && last_request + 15.minutes > now
      raise Pundit::NotAuthorizedError
    else

      Rails.cache.write(key, now, expires_at: 15.minutes)
      respond_to do |format|
        format.csv do
          set_csv_file_headers :packages
          set_streaming_headers

          response.status = 200

          # setting the body to an enumerator, rails will iterate this enumerator
          self.response_body = Enumerator.new do |y|
            y << Api::V1::RepositoryPackagePresenter.csv_header.to_s
            BuildList::Package.by_repository(@repository) do |package|
              y << Api::V1::RepositoryPackagePresenter.new(package).to_csv_row.to_s
            end
          end

        end
      end

    end
  end

  def add_repo_lock_file
    @repository.add_repo_lock_file
    render_json_response @repository, "'.repo.lock' file has been added to repository successfully"
  end

  def remove_repo_lock_file
    @repository.remove_repo_lock_file
    render_json_response @repository, "'.repo.lock' file has been removed from repository successfully"
  end

  def add_project
    if project = Project.where(id: params[:project_id]).first
      if policy(project).read?
        begin
          @repository.projects << project
          render_json_response @repository, "Project '#{project.id}' has been added to repository successfully"
        rescue ActiveRecord::RecordInvalid
          render_validation_error @repository, t('flash.repository.project_not_added')
        end
      else
        render_validation_error @repository, 'You have no access to read this project'
      end
    else
      render_validation_error @repository, "Project has not been added to repository"
    end
  end

  def remove_project
    project_id = params[:project_id]
    ProjectToRepository.where(project_id: project_id, repository_id: @repository.id).destroy_all
    render_json_response @repository, "Project '#{project_id}' has been removed from repository successfully"
  end

  def signatures
    key_pair = @repository.key_pair
    key_pair.destroy if key_pair
    key_pair = @repository.build_key_pair subject_params(Repository, KeyPair)
    key_pair.user_id = current_user.id
    authorize key_pair, :create?
    if key_pair.save
      render_json_response @repository, 'Signatures have been updated for repository successfully'
    else
      render_json_response @repository, error_message(key_pair, 'Signatures have not been updated for repository'), 422
    end
  end

  private

  # Private: before_action hook which loads Repository.
  def load_repository
    authorize @repository = Repository.find(params[:id])
  end

end
