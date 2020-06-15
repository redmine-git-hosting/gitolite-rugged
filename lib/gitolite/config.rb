# frozen_string_literal: true

module Gitolite

  class Config

    attr_accessor :repos, :groups, :filename

    def initialize(config)
      @repos    = {}
      @groups   = {}
      @filename = File.basename(config)
      process_config(config)
    end


    class << self

      def init(filename = 'gitolite.conf')
        file = Tempfile.new(filename)
        conf = new(file.path)
        conf.filename = filename # kill suffix added by Tempfile
        file.close(unlink_now = true)
        conf
      end

    end


    # TODO: merge repo unless overwrite = true
    #
    def add_repo(repo, _overwrite = false)
      unless repo.instance_of? Gitolite::Config::Repo
        raise ArgumentError, 'Repo must be of type Gitolite::Config::Repo!'
      end

      @repos[repo.name] = repo
    end


    def rm_repo(repo)
      name = normalize_repo_name(repo)
      @repos.delete(name)
    end


    def has_repo?(repo)
      name = normalize_repo_name(repo)
      @repos.key?(name)
    end


    def get_repo(repo)
      name = normalize_repo_name(repo)
      @repos[name]
    end


    def add_group(group, _overwrite = false)
      unless group.instance_of? Gitolite::Config::Group
        raise ArgumentError, 'Group must be of type Gitolite::Config::Group!'
      end

      @groups[group.name] = group
    end


    def rm_group(group)
      name = normalize_group_name(group)
      @groups.delete(name)
    end


    def has_group?(group)
      name = normalize_group_name(group)
      @groups.key?(name)
    end


    def get_group(group)
      name = normalize_group_name(group)
      @groups[name]
    end


    # rubocop:disable Metrics/AbcSize
    def to_file(path = '.', filename = @filename)
      FileUtils.mkdir_p(path) unless File.directory?(path)

      new_conf = File.join(path, filename)

      File.open(new_conf, 'w') do |f|
        f.sync = true

        # Output groups
        build_groups_depgraph.each { |group| f.write group.to_s }

        # Output repositories
        @repos.sort.each { |_k, v| f.write "\n#{v}" }

        # Output descriptions
        f.write "\n"
        f.write gitweb_descriptions.join("\n")
      end

      new_conf
    end
    # rubocop:enable Metrics/AbcSize


    def gitweb_descriptions
      @repos.sort.map { |_k, v| v.gitweb_description }.compact
    end


    private


      # Based on
      # https://github.com/sitaramc/gitolite/blob/pu/src/gl-compile-conf#cleanup_conf_line
      #
      def cleanup_config_line(line)
        # remove comments, even those that happen inline
        line.gsub!(/^((".*?"|[^#"])*)#.*/) { |m| m = $1 }

        # fix whitespace
        line.gsub!('=', ' = ')
        line.gsub!(/\s+/, ' ')
        line.strip
      end


      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength
      def process_config(config)
        # will store our context for permissions or config declarations
        context = []

        # On first call with a custom *.conf, the config might not yet exist
        return unless File.exist?(config)

        # Read each line of our config
        File.open(config, 'r').each do |l|
          line = cleanup_config_line(l)
          next if line.empty? # lines are empty if we killed a comment

          case line

          # found a repo definition
          when /^repo (.*)/
            # Empty our current context
            context = []

            repos = $1.split
            repos.each do |r|
              context << r
              @repos[r] = Repo.new(r) unless has_repo?(r)
            end

          # repo permissions
          when /^(-|C|R|RW\+?(?:C?D?|D?C?)M?) (.* )?= (.+)/
            perm = $1
            refex = $2 || ''
            users = $3.split

            context.each do |c|
              @repos[c].add_permission(perm, refex, users)
            end

          # repo git config
          when /^config (.+) = ?(.*)/
            key = $1
            value = $2

            context.each do |c|
              @repos[c].set_git_config(key, value)
            end

          # repo gitolite option
          when /^option (.+) = (.*)/
            key = $1
            value = $2

            raise ParseError, "Missing gitolite option value for repo: #{repo} and key: #{key}" if value.nil?

            context.each do |c|
              @repos[c].set_gitolite_option(key, value)
            end

          # group definition
          when /^#{Group::PREPEND_CHAR}(\S+) = ?(.*)/
            group = $1
            users = $2.split

            @groups[group] = Group.new(group) unless has_group?(group)
            @groups[group].add_users(users)

          # gitweb definition
          when /^(\S+)(?: "(.*?)")? = "(.*)"$/
            repo = $1
            owner = $2
            description = $3

            # Check for missing description
            raise ParseError, "Missing Gitweb description for repo: #{repo}" if description.nil?

            # Check for groups
            raise ParseError, 'Gitweb descriptions cannot be set for groups' if repo =~ /@.+/

            if has_repo? repo
              r = @repos[repo]
            else
              r = Repo.new(repo)
              add_repo(r)
            end

            r.owner = owner
            r.description = description

          when /^include "(.+)"/
            # TODO: implement includes
            # ignore includes for now

          when /^subconf (\S+)$/
            # TODO: implement subconfs
            # ignore subconfs for now

          else
            raise ParseError, "'#{line}' cannot be processed"
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength


      # Normalizes the various different input objects to Strings
      #
      def normalize_name(context, constant = nil)
        case context
        when constant
          context.name
        when Symbol
          context.to_s
        else
          context
        end
      end


      def method_missing(meth, *args, &block)
        if meth.to_s =~ /normalize_(\w+)_name/
          # Could use Object.const_get to figure out the constant here
          # but for only two cases, this is more readable
          case $1
          when 'repo'
            normalize_name(args[0], Gitolite::Config::Repo)
          when 'group'
            normalize_name(args[0], Gitolite::Config::Group)
          end
        else
          super
        end
      end


      # Builds a dependency tree from the groups in order to ensure all groups
      # are defined before they are used
      #
      # rubocop:disable Metrics/AbcSize
      def build_groups_depgraph
        dp = ::GRATR::Digraph.new

        # Add each group to the graph
        @groups.each_value do |group|
          dp.add_vertex! group

          # Select group names from the users
          subgroups = group.users.select { |u| u =~ /^#{Group::PREPEND_CHAR}.*$/ }.map { |g| get_group g.gsub(Group::PREPEND_CHAR, '') }

          subgroups.each do |subgroup|
            dp.add_edge! subgroup, group
          end
        end

        # Figure out if we have a good depedency graph
        dep_order = dp.topsort

        if dep_order.empty?
          raise GroupDependencyError unless @groups.empty?
        end

        dep_order
      end
      # rubocop:enable Metrics/AbcSize


      # Raised when something in a config fails to parse properly
      #
      class ParseError < RuntimeError
      end


      # Raised when group dependencies cannot be suitably resolved for output
      #
      class GroupDependencyError < RuntimeError
      end

  end
end
