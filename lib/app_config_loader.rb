# lib/app_config_loader.rb
require 'yaml'
require 'erb'
require 'json'
require 'fileutils'
require 'time'

module MyApplicationNykoliuk
  class AppConfigLoader
    class << self
      attr_reader :config_data

      def config(default_config_path, yaml_dir)
        @config_data = {}
        load_default_config(default_config_path)
        load_config(yaml_dir)
        yield @config_data if block_given?
        @config_data
      end

      def pretty_print_config_data
        puts JSON.pretty_generate(@config_data)
      end

      def load_libs
        system_libs = ['date', 'uri', 'erb']
        
        system_libs.each do |lib|
          require lib
        end

        Dir.glob(File.join(__dir__, '*.rb')).each do |file|
          require_relative File.basename(file) unless file == __FILE__
        end
      end

      private

      def load_default_config(path)
        raise "Default config file not found at #{path}" unless File.exist?(path)
        erb_content = ERB.new(File.read(path)).result
        default_config = YAML.safe_load(erb_content)
        @config_data.merge!(default_config)
      end

      def load_config(yaml_dir)
        Dir.glob(File.join(yaml_dir, '*.yaml')).each do |file_path|
          next if File.basename(file_path) == 'default_config.yaml'

          key = File.basename(file_path, '.yaml')
          content = YAML.safe_load(File.read(file_path))
          @config_data.merge!(content)
        end
      end
    end
  end
end