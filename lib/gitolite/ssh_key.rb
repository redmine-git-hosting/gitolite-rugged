require 'fileutils'

module Gitolite

  # Models an SSH key within gitolite
  # provides support for multikeys
  #
  # Types of multi keys:
  #   username: bob => <keydir>/bob/bob.pub
  #   username: bob, location: desktop => <keydir>/bob/desktop/bob.pub

  class SSHKey

    attr_accessor :owner, :location, :type, :blob, :email

    class << self

      def from_file(key)
        raise ArgumentError, "#{key} does not exist!" unless File.exists?(key)

        # Owner is the basename of the key
        # i.e., <owner>/<location>/<owner>.pub
        owner = File.basename(key, '.pub')

        # Location is the middle section of the path, if any
        location = location_from_path(File.dirname(key), owner)

        # Use string key constructor
        from_string(File.read(key), owner, location)
      end


      # Construct a SSHKey from a string
      #
      def from_string(key_string, owner, location = '')
        raise ArgumentError, 'Owner was nil, you must specify an owner' if owner.nil?

        # Get parts of the key
        type, blob, email = key_string.split

        # We need at least a type or blob
        raise ArgumentError, "'#{key_string}' is not a valid SSH key string" if type.nil? || blob.nil?

        # If the key didn't have an email, just use the owner
        email = owner if email.nil?

        new(type, blob, email, owner, location)
      end


      # Parse the key path above the key to be read.
      # As we can omit the location, there are two possible options:
      #
      # 1. Location is empty. Path is <keydir>/<owner>/
      # 2. Location is non-empty. Path is <keydir>/<owner>/<location>
      #
      # We test this by checking the parent of the given path.
      # If it equals owner, a location was set.
      # This allows the daft case of e.g., using <keydir>/bob/bob/bob.pub.
      #
      def location_from_path(path, owner)
        keyroot = File.dirname(path)
        File.basename(keyroot) == owner ? File.basename(path) : ''
      end


      def delete_dir_if_empty(dir)
        Dir.rmdir(dir) if File.directory?(dir) && Dir["#{dir}/*"].empty?
      rescue => e
        STDERR.puts("Warning: Couldn't delete empty directory: #{e.message}")
      end


      # Remove a key given a relative path
      #
      # Unlinks the key file and removes any empty parent directory
      # below key_dir
      #
      def remove(key_file, key_dir_path)
        abs_key_path = File.join(key_dir_path, key_file)
        key = from_file(abs_key_path)

        # Remove the file itself
        File.unlink(abs_key_path)

        key_owner_dir = File.join(key_dir_path, key.owner)

        # Remove the location, if it exists and is empty
        delete_dir_if_empty(File.join(key_owner_dir, key.location)) if key.location


        # Remove the owner dir, if empty
        delete_dir_if_empty(key_owner_dir)
      end

    end


    def initialize(type, blob, email, owner = nil, location = '')
      @type     = type
      @blob     = blob
      @email    = email
      @owner    = owner || email
      @location = location
    end


    def to_s
      [@type, @blob, @email].join(' ')
    end


    def to_file(path)
      # Ensure multi-key directory structure
      # <keydir>/<owner>/<location?>/<owner>.pub
      key_dir  = File.join(path, @owner, @location)
      key_file = File.join(key_dir, filename)

      # Ensure subdirs exist
      FileUtils.mkdir_p(key_dir) unless File.directory?(key_dir)

      File.open(key_file, 'w') do |f|
        f.sync = true
        f.write(to_s)
      end
      key_file
    end


    def relative_path
      File.join(@owner, @location, filename)
    end


    def filename
      [@owner, '.pub'].join
    end


    def ==(key)
      @type == key.type &&
      @blob == key.blob &&
      @email == key.email &&
      @owner == key.owner &&
      @location == key.location
    end


    def hash
      [@owner, @location, @type, @blob, @email].hash
    end

  end
end
