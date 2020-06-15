# frozen_string_literal: true

module Gitolite
  class GitoliteAdmin
    module Config

      ####################
      #  Path accessors  #
      ####################

      def config_dir_path
        File.join(path, @settings[:config_dir])
      end


      def config_file_path
        File.join(config_dir_path, @settings[:config_file])
      end


      # Returns the relative directory to the gitolite config file location.
      # I.e., settings[config_dir]/settings[config_file]
      # Defaults to 'conf/gitolite.conf'
      #
      def relative_config_file
        File.join(@settings[:config_dir], @settings[:config_file])
      end


      ######################
      #  Config accessors  #
      ######################

      def config
        @config ||= load_config
      end


      def config=(config)
        @config = config
      end


      private


        def load_config
          Gitolite::Config.new(config_file_path)
        end


        def save_config_file(index)
          @config.to_file(config_dir_path)
          index.add(relative_config_file)
        end

    end
  end
end
