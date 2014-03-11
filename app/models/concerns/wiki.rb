module Wiki
  extend ActiveSupport::Concern

  included do
    after_save :create_wiki
    after_destroy :destroy_wiki
  end

  def wiki_path
    build_path(wiki_repo_name)
  end

  def wiki_repo_name
    File.join owner.uname, "#{name}.wiki"
  end

  protected

  def create_wiki
    if has_wiki && !FileTest.exist?(wiki_path)
      Grit::Repo.init_bare(wiki_path)
      wiki = Gollum::Wiki.new(wiki_path, {base_path: Rails.application.routes.url_helpers.project_wiki_index_path(owner, self)})
      wiki.write_page('Home', :markdown, I18n.t("wiki.seed.welcome_content"),
                      {name: owner.name, email: owner.email, message: 'Initial commit'})
    end
  end

  def destroy_wiki
    FileUtils.rm_rf wiki_path
  end
end
