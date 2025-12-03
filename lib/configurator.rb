# configurator.rb
# frozen_string_literal: true

require_relative 'logger_manager'

module MyApplicationNykoliuk
  class Configurator
    attr_reader :config

    def self.available_methods
      [
        :run_website_parser,
        :run_save_to_csv,
        :run_save_to_json,
        :run_save_to_yaml,
        :run_save_to_sqlite,
        :run_save_to_mongodb
      ]
    end

    def initialize
      @config = {}
      
      self.class.available_methods.each do |key|
        @config[key] = 0
      end
      
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Configurator ініціалізовано зі значеннями за замовчуванням: #{@config}")
    end

    def configure(overrides)
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Старт налаштування Configurator.")
      
      overrides.each do |key, value|
        if @config.key?(key)
          @config[key] = value
          MyApplicationNykoliuk::LoggerManager.log_processed_file("Configurator: Параметр '#{key}' оновлено до: #{value}")
        else
          warning_message = "Configurator Warning: Недійсний ключ конфігурації '#{key}'. Пропущено."
          puts "⚠️ #{warning_message}"
          MyApplicationNykoliuk::LoggerManager.log_error(warning_message)
        end
      end
      
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Configurator налаштування завершено. Поточні конфігурації: #{@config}")
    end
    
    def run_action?(key)
      @config[key] == 1
    end
  end
end