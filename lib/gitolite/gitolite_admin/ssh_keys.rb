# frozen_string_literal: true

module Gitolite
  class GitoliteAdmin
    module SshKeys

      ####################
      #  Path accessors  #
      ####################

      def key_dir_path
        File.join(path, relative_key_dir)
      end


      # Returns the relative directory to the public key location.
      # I.e., settings[key_dir]/settings[key_subdir]
      # Defaults to 'keydir/'
      #
      def relative_key_dir
        File.join(@settings[:key_dir], @settings[:key_subdir])
      end


      ########################
      #  SSH Keys accessors  #
      ########################

      def ssh_keys
        @ssh_keys ||= load_keys
      end


      def add_key(key)
        raise ArgumentError, 'Key must be of type Gitolite::SSHKey!' unless key.instance_of? Gitolite::SSHKey

        ssh_keys[key.owner] << key
        true
      end


      def rm_key(key)
        raise ArgumentError, 'Key must be of type Gitolite::SSHKey!' unless key.instance_of? Gitolite::SSHKey

        ssh_keys[key.owner].delete(key) ? true : false
      end


      private


        # Loads all .pub files in the gitolite-admin
        # keydir directory
        def load_keys
          keys = Hash.new { |k, v| k[v] = DirtyProxy.new([]) }

          list_keys.each do |key|
            new_key = SSHKey.from_file(key)
            keys[new_key.owner] << new_key
          end

          # Mark key sets as unmodified (for dirty checking)
          keys.each_value(&:clean_up!)
          keys
        end


        def list_keys
          Dir.glob(key_dir_path + '/**/*.pub')
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


        def current_files
          list_keys.map { |f| relative_key_path(f) }
        end


        def current_keys
          @ssh_keys.values.map { |f| f.map(&:relative_path) }.flatten
        end


        def add_ssh_keys(index)
          @ssh_keys.each_value do |key|
            # Write only keys from sets that has been modified
            next if key.respond_to?(:dirty?) && !key.dirty?

            key.each do |k|
              k.to_file(key_dir_path)
              index.add File.join(relative_key_dir, k.relative_path)
            end
          end
        end


        # Returns the relative key path
        # <owner>/<location>/<owner> given an absolute path
        # below the keydir.
        def relative_key_path(key_path)
          Pathname.new(key_path).relative_path_from(Pathname.new(key_dir_path)).to_s
        end

    end
  end
end
