module Gitolite
  class GitoliteAdmin
    module Accessors

      ##########################
      #  Repository accessors  #
      ##########################

      # Clone the gitolite-admin repo
      # to the given path.
      #
      # The repo is cloned from the url
      # +(:git_user)@(:hostname)/gitolite-admin.git+
      #
      # The hostname may use an optional :port to allow for custom SSH ports.
      # E.g., +git@localhost:2222/gitolite-admin.git+
      #
      def clone
        clean_up
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


      def clean_up
        FileUtils.rm_rf(path) if exists?
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
        File.open(lock_file_path, File::RDWR|File::CREAT, 0644) do |file|
          # Get lock
          file.sync = true
          file.flock(File::LOCK_EX)

          # Execute block
          yield

          # Push all changes
          apply

          # Release lock
          file.flock(File::LOCK_UN)
        end
      end

    end
  end
end
