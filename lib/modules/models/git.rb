# -*- encoding : utf-8 -*-
module Modules
  module Models
    module Git
      extend ActiveSupport::Concern

      included do
        validates_attachment_size :srpm, :less_than => 500.megabytes
        validates_attachment_content_type :srpm, :content_type => ['application/octet-stream', "application/x-rpm", "application/x-redhat-package-manager"], :message => I18n.t('layout.invalid_content_type')

        has_attached_file :srpm
        # attr_accessible :srpm

        after_create :create_git_repo
        after_commit(:on => :create) {|p| p.fork_git_repo unless p.is_root?} # later with resque
        after_commit(:on => :create) {|p| p.import_attached_srpm if p.srpm?} # later with resque # should be after create_git_repo
        after_destroy :destroy_git_repo
        # after_rollback lambda { destroy_git_repo rescue true if new_record? }

        later :import_attached_srpm, :queue => :fork_import
        later :fork_git_repo, :queue => :fork_import
      end

      def repo
        @repo ||= Grit::Repo.new(path) rescue Grit::Repo.new(GAP_REPO_PATH)
      end

      def path
        build_path(git_repo_name)
      end

      def git_repo_name
        File.join owner.uname, name
      end

      def versions
        repo.tags.map(&:name) + repo.branches.map(&:name)
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

        index.add(path, data)
        index.commit(message, :parents => [parent], :actor => actor, :last_tree => parent.tree.id, :head => head)
      end

      def paginate_commits(treeish, options = {})
        options[:page] = options[:page].try(:to_i) || 1
        options[:per_page] = options[:per_page].try(:to_i) || 20

        skip = options[:per_page] * (options[:page] - 1)
        last_page = (skip + options[:per_page]) >= repo.commit_count(treeish)

        [repo.commits(treeish, options[:per_page], skip), options[:page], last_page]
      end

      def tree_info(tree, treeish = nil, path = nil)
        treeish ||= tree.id
        # initialize result as hash of <tree_entry> => nil
        res = (tree.trees.sort + tree.blobs.sort).inject({}){|h, e| h.merge!({e => nil})}
        # fills result vith commits that describes this file
        res = res.inject(res) do |h, (entry, commit)|
          if commit.nil? and entry.respond_to?(:name) # only if commit == nil
            # ... find last commit corresponds to this file ...
            c = repo.log(treeish, File.join([path, entry.name].compact), :max_count => 1).first
            # ... and add it to result.
            h[entry] = c
            # find another files, that linked to this commit and set them their commit
            # c.diffs.map{|diff| diff.b_path.split(File::SEPARATOR, 2).first}.each do |name|
            #   h.each_pair do |k, v|
            #     h[k] = c if k.name == name and v.nil?
            #   end
            # end
          end
          h
        end
      end

      def import_srpm(srpm_path = srpm.path, branch_name = 'import')
        token = User.find_by_uname('rosa_system').authentication_token
        opts = [srpm_path, path, branch_name, Rails.root.join('bin', 'file-store.rb'), token, APP_CONFIG['file_store_url']].join(' ')
        system("#{Rails.root.join('bin', 'import_srpm.sh')} #{opts} >> /dev/null 2>&1")
      end

      protected

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

      def fork_git_repo
        dummy = Grit::Repo.new(path) rescue parent.repo.fork_bare(path, :shared => false)
        write_hook
      end

      def destroy_git_repo
        FileUtils.rm_rf path
      end

      def write_hook
        is_production = Rails.env == "production"
        hook = File.join(::Rails.root.to_s, 'tmp', "post-receive-hook")
        FileUtils.cp(File.join(::Rails.root.to_s, 'bin', "post-receive-hook.partial"), hook)
        File.open(hook, 'a') do |f|
          s = "\n  /bin/bash -l -c \"cd #{is_production ? '/srv/rosa_build/current' : Rails.root.to_s} && #{is_production ? 'RAILS_ENV=production' : ''} bundle exec rake hook:enqueue[$owner,$reponame,$newrev,$oldrev,$ref,$newrev_type,$oldrev_type]\""
          s << " > /dev/null 2>&1" if is_production
          s << "\ndone\n"
          f.write(s)
          f.chmod(0755)
        end

        hook_file = File.join(path, 'hooks', 'post-receive')
        FileUtils.cp(hook, hook_file)
        FileUtils.rm_rf(hook)

      rescue Exception # FIXME
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
        def process_hook(owner_uname, repo, newrev, oldrev, ref, newrev_type, oldrev_type)
          rec = GitHook.new(owner_uname, repo, newrev, oldrev, ref, newrev_type, oldrev_type)
          ActivityFeedObserver.instance.after_create rec
        end
      end
    end
  end
end
