require 'pathname'

module Gitolite
  class GitoliteAdmin

    # Default settings
    DEFAULTS = {
      # clone/push url settings
      git_user: 'git',
      host: 'localhost',

      # Commit settings
      author_name:  'gitolite-rugged gem',
      author_email: 'gitolite-rugged@localhost',
      commit_msg:   'Commited by the gitolite-rugged gem',

      # Gitolite-Admin settings
      config_dir:     'conf',
      key_dir:        'keydir',
      key_subdir:     '',
      config_file:    'gitolite.conf',
      lock_file_path: '.lock',
      local_branch:   'master',
      remote_branch:  'master',

      # Repo settings
      update_on_init:      true,
      reset_before_update: true
    }


    attr_reader :repo
    attr_reader :path

    # Intialize with the path to
    # the gitolite-admin repository
    #
    # Settings:
    # [Connection]
    # :git_user: The git user to SSH to (:git_user@localhost:gitolite-admin.git), defaults to 'git'
    # :private_key: The key file containing the private SSH key for :git_user
    # :public_key: The key file containing the public SSH key for :git_user
    # :host: Host for clone url. Defaults to 'localhost'
    #
    # [Gitolite-Admin]
    # :config_dir: Config directory within gitolite repository (defaults to 'conf')
    # :key_dir: Public key directory within gitolite repository (defaults to 'keydir')
    # :config_file: Config file to parse (default: 'gitolite.conf')
    # **use only when you use the 'include' directive of gitolite)**
    # :key_subdir: Where to store gitolite-rugged known keys, defaults to '' (i.e., directly in keydir)
    # :lock_file_path: location of the transaction lockfile, defaults to <gitolite-admin.git>/.lock
    #
    # The settings hash is forwarded to +GitoliteAdmin.new+ as options.
    #
    def initialize(path, settings = {})
      @path     = path
      @settings = DEFAULTS.merge(settings)

      # Ensure SSH key settings exist
      @settings.fetch(:public_key)
      @settings.fetch(:private_key)

      # Set repository instance variable
      set_repo

      # Load Gitolite config
      reload!
    end


    class << self

      # Checks if the given path is a gitolite-admin repository.
      # A valid repository contains a conf folder, keydir folder,
      # and a configuration file within the conf folder.
      #
      def is_gitolite_admin_repo?(dir)
        # First check if it is a git repository
        begin
          repo = Rugged::Repository.new(dir)
          return false if repo.empty?
        rescue Rugged::RepositoryError, Rugged::OSError
          return false
        end

        # Check if config file, key directory exist
        [
          File.join(dir, DEFAULTS[:config_dir]),
          File.join(dir, DEFAULTS[:key_dir]),
          File.join(dir, DEFAULTS[:config_dir], DEFAULTS[:config_file])
        ].each { |f| return false unless File.exists?(f) }

        true
      end

    end


    def admin_url
      ['ssh://', @settings[:git_user], '@', @settings[:host], '/gitolite-admin.git'].join
    end


    def commit_author
      { email: @settings[:author_email], name: @settings[:author_name] }.clone
    end


    ####################
    #  Path accessors  #
    ####################

    def config_dir_path
      File.join(path, @settings[:config_dir])
    end


    def config_file_path
      File.join(config_dir_path, @settings[:config_file])
    end


    def key_dir_path
      File.join(path, relative_key_dir)
    end


    # Returns the relative directory to the gitolite config file location.
    # I.e., settings[config_dir]/settings[config_file]
    # Defaults to 'conf/gitolite.conf'
    #
    def relative_config_file
      File.join(@settings[:config_dir], @settings[:config_file])
    end


    # Returns the relative directory to the public key location.
    # I.e., settings[key_dir]/settings[key_subdir]
    # Defaults to 'keydir/'
    #
    def relative_key_dir
      File.join(@settings[:key_dir], @settings[:key_subdir])
    end


    def lock_file_path
      File.expand_path(@settings[:lock_file_path], path)
    end


    ######################
    #  Config accessors  #
    ######################

    # This method will destroy the in-memory data structures and reload everything
    # from the file system
    #
    def reload!
      @ssh_keys = load_keys
      @config   = load_config
    end


    def config
      @config ||= load_config
    end


    def config=(config)
      @config = config
    end


    ########################
    #  SSH Keys accessors  #
    ########################

    def ssh_keys
      @ssh_keys ||= load_keys
    end


    def add_key(key)
      raise GitoliteAdminError, 'Key must be of type Gitolite::SSHKey!' unless key.instance_of? Gitolite::SSHKey
      ssh_keys[key.owner] << key
    end


    def rm_key(key)
      raise GitoliteAdminError, 'Key must be of type Gitolite::SSHKey!' unless key.instance_of? Gitolite::SSHKey
      ssh_keys[key.owner].delete key
    end


    ##########################
    #  Repository accessors  #
    ##########################

    # Clone the gitolite-admin repo
    # to the given path.
    #
    # The repo is cloned from the url
    # +(:git_user)@(:host)/gitolite-admin.git+
    #
    # The host may use an optional :port to allow for custom SSH ports.
    # E.g., +git@localhost:2222/gitolite-admin.git+
    #
    def clone
      clean_up_gitolite_dir
      Rugged::Repository.clone_at(admin_url, path, credentials: credentials)
    end


    # This method will destroy all local tracked changes, resetting the local gitolite
    # git repo to HEAD
    #
    def reset!
      repo.reset('origin/master', :hard)
    end


    # Push back to origin
    #
    def apply
      repo.push('origin', ['refs/heads/master'], credentials: credentials)
    end


    # Commits all staged changes and pushes back to origin
    #
    def save_and_apply(commit_msg = nil)
      save(commit_msg)
      apply
    end


    # Writes all changed aspects out to the file system
    # will also stage all changes then commit
    #
    def save(commit_msg = nil)
      # Add all changes to index (staging area)
      index = repo.index

      # Process config file (if loaded, i.e. may be modified)
      save_config_file(index) if @config

      # Process ssh keys (if loaded, i.e. may be modified)
      save_ssh_keys(index) if @ssh_keys

      # Write index to git and resync fs
      commit_tree = index.write_tree(repo)
      index.write

      author = commit_author.merge(time: Time.now)

      Rugged::Commit.create(repo,
        parents:    [repo.head.target],
        tree:       commit_tree,
        update_ref: 'HEAD',
        message:    (commit_msg || @settings[:commit_msg]),
        author:     author,
        committer:  author
      )
    end


    # Updates the repo with changes from remote master
    # Warning: This resets the repo before pulling in the changes.
    #
    def update
      # Reset --hard repo before update
      reset! if @settings[:reset_before_update]

      # Fetch changes from origin
      repo.fetch('origin', credentials: credentials)

      # Create the merged index in memory
      merge_index = repo.merge_commits(local_branch, remote_branch)

      # Complete the merge by comitting it
      Rugged::Commit.create(repo,
        parents:    [local_branch, remote_branch],
        tree:       merge_index.write_tree(repo),
        update_ref: update_ref,
        message:    update_message,
        author:     commit_author,
        committer:  commit_author
      )

      reload!
    end


    # Lock the gitolite-admin directory and yield.
    # After the block is completed, calls +apply+ only.
    # You have to commit your changes within the transaction block
    #
    def transaction(&block)
      get_lock do
        yield

        # Push all changes
        apply
      end
    end


    private


      def set_repo
        if self.class.is_gitolite_admin_repo?(path)
          @repo = Rugged::Repository.new(path, credentials: credentials)
          # Update repository if asked
          update if @settings[:update_on_init]
        else
          @repo = clone
        end
      end


      def credentials
        @credentials ||=
          Rugged::Credentials::SshKey.new(
            username:   @settings[:git_user],
            publickey:  @settings[:public_key],
            privatekey: @settings[:private_key]
          )
      end


      def clean_up_gitolite_dir
        FileUtils.rm_rf(path) if Dir.exists?(path)
      end


      def load_config
        Config.new(config_file_path)
      end


      # Loads all .pub files in the gitolite-admin
      # keydir directory
      def load_keys
        keys = Hash.new { |k, v| k[v] = DirtyProxy.new([]) }

        list_keys.each do |key|
          new_key = SSHKey.from_file(key)
          keys[new_key.owner] << new_key
        end

        # Mark key sets as unmodified (for dirty checking)
        keys.values.each{ |set| set.clean_up! }
        keys
      end


      def list_keys
        Dir.glob(key_dir_path + '/**/*.pub')
      end


      def save_config_file(index)
        new_conf = @config.to_file(config_dir_path)
        index.add(relative_config_file)
      end


      def save_ssh_keys(index)
        remove_ssh_keys(index)
        add_ssh_keys(index)
      end


      def remove_ssh_keys(index)
        (current_files - current_keys).each do |key|
          SSHKey.remove(key, key_dir_path)
          index.remove File.join(relative_key_dir, key)
        end
      end


      def add_ssh_keys(index)
        @ssh_keys.each_value do |key|
          # Write only keys from sets that has been modified
          next if key.respond_to?(:dirty?) && !key.dirty?
          key.each do |k|
            new_key = k.to_file(key_dir_path)
            index.add File.join(relative_key_dir, k.relative_path)
          end
        end
      end


      def current_files
        list_keys.map { |f| relative_key_path(f) }
      end


      def current_keys
        @ssh_keys.values.map { |f| f.map { |t| t.relative_path } }.flatten
      end


      # Returns the relative key path
      # <owner>/<location>/<owner> given an absolute path
      # below the keydir.
      def relative_key_path(key_path)
        Pathname.new(key_path).relative_path_from(Pathname.new(key_dir_path)).to_s
      end


      def local_branch
        repo.references["refs/heads/#{@settings[:local_branch]}"].target
      end


      def remote_branch
        repo.references["refs/remotes/origin/#{@settings[:remote_branch]}"].target
      end


      def update_ref
        "refs/heads/#{@settings[:local_branch]}"
      end


      def update_message
        "[gitolite-rugged] Merged `origin/#{@settings[:remote_branch]}` into `#{@settings[:local_branch]}`"
      end


      # Aquire LOCK_EX on the gitolite-admin.git directory .
      # Use +GitoliteAdmin.transaction+ to modify with flock.
      #
      def get_lock(&block)
        File.open(lock_file_path, File::RDWR|File::CREAT, 0644) do |file|
          file.sync = true
          file.flock(File::LOCK_EX)
          yield
          file.flock(File::LOCK_UN)
        end
      end

  end
end
