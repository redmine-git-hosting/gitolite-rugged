module Gitolite
  class GitoliteAdmin

    # Default settings
    DEFAULTS = {
      # clone/push url settings
      git_user: 'git',
      hostname: 'localhost',

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

    include GitoliteAdmin::Accessors
    include GitoliteAdmin::Config
    include GitoliteAdmin::SshKeys

    attr_reader :repo
    attr_reader :path

    # Intialize with the path to
    # the gitolite-admin repository
    #
    # Settings:
    # [Connection]
    # :private_key: The key file containing the private SSH key for :git_user
    # :public_key: The key file containing the public SSH key for :git_user
    # :git_user: The git user to SSH to (:git_user@localhost:gitolite-admin.git), defaults to 'git'
    # :hostname: Hostname for clone url. Defaults to 'localhost'
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
      @repo = set_repo

      # Update repository if asked
      update if @settings[:update_on_init]

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
      ['ssh://', @settings[:git_user], '@', @settings[:hostname], '/gitolite-admin.git'].join
    end


    def commit_author
      { email: @settings[:author_email], name: @settings[:author_name] }.clone
    end


    def exists?
      Dir.exists?(path)
    end


    def lock_file_path
      File.expand_path(@settings[:lock_file_path], path)
    end


    def local_branch
      get_references "refs/heads/#{@settings[:local_branch]}"
    end


    def remote_branch
      get_references "refs/remotes/origin/#{@settings[:remote_branch]}"
    end


    def update_ref
      "refs/heads/#{@settings[:local_branch]}"
    end


    def update_message
      "[gitolite-rugged] Merged `origin/#{@settings[:remote_branch]}` into `#{@settings[:local_branch]}`"
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


    def credentials
      @credentials ||=
        Rugged::Credentials::SshKey.new(
          username:   @settings[:git_user],
          publickey:  @settings[:public_key],
          privatekey: @settings[:private_key]
        )
    end


    def get_references(name)
      ref = repo.references[name]
      return nil if ref.nil?
      ref.target
    end


    private


      def set_repo
        if self.class.is_gitolite_admin_repo?(path)
          Rugged::Repository.new(path, credentials: credentials)
        else
          clone
        end
      end

  end
end
