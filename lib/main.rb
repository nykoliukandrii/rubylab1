# lib/main.rb
# frozen_string_literal: true

require_relative 'app_config_loader'

MyApplicationNykoliuk::AppConfigLoader.load_libs 

puts "=== Старт системи ==="

DEFAULT_CONFIG_PATH = File.expand_path('../config/default_config.yaml', __dir__)
CONFIG_DIR = File.expand_path('../config/', __dir__)

begin
  config_data = MyApplicationNykoliuk::AppConfigLoader.config(DEFAULT_CONFIG_PATH, CONFIG_DIR)
  puts "✅ Конфігурації успішно завантажено."

  puts "\n=== Завантажені Конфігурації (JSON) ==="
  MyApplicationNykoliuk::AppConfigLoader.pretty_print_config_data
  puts "======================================="

  MyApplicationNykoliuk::LoggerManager.configure(config_data)
  MyApplicationNykoliuk::LoggerManager.log_processed_file("Система успішно налаштована та запущена.")
  MyApplicationNykoliuk::LoggerManager.log_error("Це тестова помилка логера.")

  web_config_path = File.join(CONFIG_DIR, 'web_parser.yaml') 
  parser = MyApplicationNykoliuk::Parser.new(web_config_path)
  parser.parse_facts

  puts "\n✅ Перевірка функціоналу завершена. Перевірте лог-файли в папці logs/."

rescue => e
  puts "\n❌ КРИТИЧНА ПОМИЛКА СИСТЕМИ: #{e.message}"
end