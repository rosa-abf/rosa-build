require 'nokogiri'
require 'open-uri'

module Git
  extend ActiveSupport::Concern

  included do
    CONTENT_LIMIT = 200

    has_attached_file :srpm

    validates_attachment_size :srpm, less_than_or_equal_to: 500.megabytes
    validates_attachment_content_type :srpm, content_type: ['application/octet-stream', "application/x-rpm", "application/x-redhat-package-manager"], message: I18n.t('layout.invalid_content_type')

    after_create :create_git_repo
    after_commit(on: :create) {|p| p.fork_git_repo unless p.is_root?} # later with resque
    after_commit(on: :create) {|p| p.import_attached_srpm if p.srpm?} # later with resque # should be after create_git_repo
    after_destroy :destroy_git_repo
    # after_rollback -> { destroy_git_repo rescue true if new_record? }

    later :import_attached_srpm, queue: :fork_import
    later :fork_git_repo, queue: :fork_import
  end

  def repo
    @repo ||= Grit::Repo.new(path) rescue Grit::Repo.new(GAP_REPO_PATH)
  end

  def path
    build_path(name_with_owner)
  end

  def versions
    repo.tags.map(&:name) + repo.branches.map(&:name)
  end

  def find_blob_and_raw_of_spec_file(project_version)
    blob = repo.tree(project_version).contents.find{ |n| n.is_a?(Grit::Blob) && n.name =~ /.spec$/ }
    return unless blob

    raw = Grit::GitRuby::Repository.new(repo.path).get_raw_object_by_sha1(blob.id)
    [blob, raw]
  end

  def create_branch(new_ref, from_ref, user)
    return false if new_ref.blank? || from_ref.blank? || !(from_commit = repo.commit(from_ref))
    status, out, err = repo.git.native(:branch, {process_info: true}, new_ref, from_commit.id)
    if status == 0
      Resque.enqueue(GitHook, owner.uname, name, from_commit.id, GitHook::ZERO, "refs/heads/#{new_ref}", 'commit', "user-#{user.id}", nil)
      return true
    end
    return false

  end

  def delete_branch(branch, user)
    return false if default_branch == branch.name
    message = repo.git.native(:branch, {}, '-D', branch.name)
    if message.present?
      Resque.enqueue(GitHook, owner.uname, name, GitHook::ZERO, branch.commit.id, "refs/heads/#{branch.name}", 'commit', "user-#{user.id}", message)
    end
    return message.present?
  end

  def update_file(path, data, options = {})
    head = options[:head].to_s || default_branch
    actor = get_actor(options[:actor])
    filename = File.split(path).last
    message = options[:message]
    message = "Updated file #{filename}" if message.nil? or message.empty?

    # can not write to unexisted branch
    return false if repo.branches.select{|b| b.name == head}.size != 1

    parent = repo.commits(head).first

    index = repo.index
    index.read_tree(parent.tree.id)

    # can not create new file
    return false if (index.current_tree / path).nil?

    system "sudo chown -R rosa:rosa #{repo.path}" #FIXME Permission denied - /mnt/gitstore/git_projects/...
    index.add(path, data)
    if sha1 = index.commit(message, parents: [parent], actor: actor, last_tree: parent.tree.id, head: head)
      Resque.enqueue(GitHook, owner.uname, name, sha1, sha1, "refs/heads/#{head}", 'commit', "user-#{options[:actor].id}", message)
    end
    sha1
  end

  def paginate_commits(treeish, options = {})
    options[:page] = options[:page].try(:to_i) || 1
    options[:per_page] = options[:per_page].try(:to_i) || 20

    skip = options[:per_page] * (options[:page] - 1)
    last_page = (skip + options[:per_page]) >= repo.commit_count(treeish)

    [repo.commits(treeish, options[:per_page], skip), options[:page], last_page]
  end

  def tree_info(tree, treeish = nil, path = nil, page = 0)
    return [] unless tree
    grouped = tree.contents.sort_by{|c| c.name.downcase}.group_by(&:class)
    contents = [
      grouped[Grit::Tree],
      grouped[Grit::Blob],
      grouped[Grit::Submodule]
    ].compact.flatten
    range = page*CONTENT_LIMIT..CONTENT_LIMIT+page*(CONTENT_LIMIT)-1
    contents[range].map do |node|
      node_path = File.join([path.present? ? path : nil, node.name].compact)
      [
        node,
        node_path,
        repo.log(treeish, node_path, max_count: 1).first
      ]
    end
  end

  def import_srpm(srpm_path = srpm.path, branch_name = 'import')
    token = User.find_by(uname: 'rosa_system').authentication_token
    opts = [srpm_path, path, branch_name, Rails.root.join('bin', 'file-store.rb'), token, APP_CONFIG['file_store_url']].join(' ')
    system("#{Rails.root.join('bin', 'import_srpm.sh')} #{opts} >> /dev/null 2>&1")
  end

  def is_empty?
    repo.branches.count == 0
  end

  def total_commits_count
    return 0 if is_empty?
    %x(cd #{path} && git rev-list --all | wc -l).to_i
  end

  protected

  def aliases_path
    File.join(APP_CONFIG['git_path'], 'git_projects', '.aliases')
  end

  def alias_path
    File.join(aliases_path, "#{alias_from_id}.git")
  end

  def build_path(dir)
    File.join(APP_CONFIG['git_path'], 'git_projects', "#{dir}.git")
  end

  def import_attached_srpm
    if srpm?
      import_srpm # srpm.path
      self.srpm = nil; save # clear srpm
    end
  end

  def create_git_repo
    if is_root?
      Grit::Repo.init_bare(path)
      write_hook
    end
  end

  # Creates fork/alias for GIT repo
  def fork_git_repo
    dummy = Grit::Repo.new(path) rescue nil
    # Do nothing if GIT repo already exist
    unless dummy
      if alias_from_id
        FileUtils.mkdir_p(aliases_path)
        if !Dir.exists?(alias_path) && alias_from
          # Move GIT repo into aliases
          FileUtils.mv(alias_from.path, alias_path, force: true)
          # Create link for GIT
          FileUtils.ln_sf alias_path, alias_from.path
        end
        # Create link for GIT
        FileUtils.ln_sf alias_path, path
      else
        parent.repo.fork_bare(path, shared: false)
      end
    end
    write_hook
  end

  def destroy_git_repo
    FileUtils.rm_rf path
    return unless alias_from_id
    unless Project.where.not(id: id).where(alias_from_id: alias_from_id).exists?
      FileUtils.rm_rf alias_path
    end
  end

  def write_hook
    hook = "/home/#{APP_CONFIG['shell_user']}/gitlab-shell/hooks/post-receive"
    hook_file = File.join(path, 'hooks', 'post-receive')
    FileUtils.ln_sf hook, hook_file
  end

  def get_actor(actor = nil)
    @last_actor = case actor.class.to_s
      when 'Grit::Actor' then options[:actor]
      when 'Hash'        then Grit::Actor.new(actor[:name], actor[:email])
      when 'String'      then Grit::Actor.from_stirng(actor)
      else begin
        if actor.respond_to?(:name) and actor.respond_to?(:email)
          Grit::Actor.new(actor.name, actor.email)
        else
          config = Grit::Config.new(repo)
          Grit::Actor.new(config['user.name'], config['user.email'])
        end
      end
    end
    @last_actor
  end

  module ClassMethods
    MAX_SRC_SIZE = 1024*1024*256

    def process_hook(owner_uname, repo, newrev, oldrev, ref, newrev_type, user = nil, message = nil)
      rec = GitHook.new(owner_uname, repo, newrev, oldrev, ref, newrev_type, user, message)
      Modules::Observers::ActivityFeed::Git.create_notifications rec
    end

    def run_mass_import(url, srpms_list, visibility, owner, add_to_repository_id)
      doc = Nokogiri::HTML(open(url))
      links = doc.css("a[href$='.src.rpm']")
      return if links.count == 0
      filter = srpms_list.lines.map(&:chomp).map(&:strip).select(&:present?)

      repository = Repository.find add_to_repository_id
      platform = repository.platform
      dir = Dir.mktmpdir 'mass-import-', APP_CONFIG['tmpfs_path']
      links.each do |link|
        begin
          package = link.attributes['href'].value
          package.chomp!; package.strip!

          next if package.size == 0 || package !~ Project::NAME_REGEXP
          next if filter.present? && !filter.include?(package)

          uri = URI "#{url}/#{package}"
          srpm_file = "#{dir}/#{package}"
          Net::HTTP.start(uri.host) do |http|
            if http.request_head(uri.path)['content-length'].to_i < MAX_SRC_SIZE
              f = open(srpm_file, 'wb')
              http.request_get(uri.path) do |resp|
                resp.read_body{ |segment| f.write(segment) }
              end
              f.close
            end
          end
          if name = `rpm -q --qf '[%{Name}]' -p #{srpm_file}` and $?.success? and name.present?
            next if owner.projects.exists?(name: name)
            description = `rpm -q --qf '[%{Description}]' -p #{srpm_file}`.scrub('')

            project = owner.projects.build(
              name:        name,
              description: description,
              visibility:  visibility,
              is_package:  false # See: Hook for #attach_to_personal_repository
            )
            project.owner = owner
            if project.save
              repository.projects << project rescue nil
              project.update_attributes(is_package: true)
              project.import_srpm srpm_file, platform.name
            end
          end
        rescue => e
          f.close if defined?(f)
          Airbrake.notify_or_ignore(e, link: link.to_s, url: url, owner: owner)
        ensure
          File.delete srpm_file if srpm_file
        end
      end
    rescue => e
      Airbrake.notify_or_ignore(e, url: url, owner: owner)
    ensure
      FileUtils.remove_entry_secure dir if dir
    end
  end
end
