# lib/main.rb
# frozen_string_literal: true

require_relative 'app_config_loader'
require_relative 'item'
require_relative 'item_container'
require_relative 'item_collection'
require_relative 'parser'
require_relative 'simple_website_parser'

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

  test_item_1 = MyApplicationNykoliuk::Item.new(name: "Test Book 1", price: 99.99) do |i|
    i.description = "Опис через блок при створенні."
  end
  puts test_item_1.info 
  
  test_item_1.update do |i|
    i.price = 150.00
    i.category = "Programming"
  end
  puts "Оновлена ціна: #{test_item_1.price}"
  
  test_item_2 = MyApplicationNykoliuk::Item.generate_fake
  puts "Тестова ціна 2: #{test_item_2.price}"
  puts "Порівняння цін (150.00 <=> #{test_item_2.price}): #{test_item_1 <=> test_item_2}" 
  puts "=============================="


  puts "\n=== ТЕСТУВАННЯ ITEMCOLLECTION (CART) ==="
  
  cart = MyApplicationNykoliuk::ItemCollection.new
  puts "Інфо про клас: #{MyApplicationNykoliuk::ItemCollection.class_info}"
  puts "Кількість створених об'єктів ItemCollection: #{MyApplicationNykoliuk::ItemCollection.item_collection_count}"
  
  cart.generate_test_items(10)
  
  cart.show_all_items 
  
  puts "\n--- Тестування Enumerable ---"
  puts "Загальна вартість: #{cart.total_price.round(2)} грн."
  puts "Кількість дорогих товарів (>50 грн): #{cart.select_expensive.count}"
  puts "Найдорожчий товар (sorted): #{cart.sort_by_price.last.name}"
  
  output_dir = File.expand_path('../output/test_collection', __dir__)
  FileUtils.mkdir_p(output_dir) 

  puts "\n--- Збереження тестових даних ---"
  cart.save_to_file(File.join(output_dir, 'items.txt'))
  cart.save_to_json(File.join(output_dir, 'items.json'))
  cart.save_to_csv(File.join(output_dir, 'items.csv'))
  cart.save_to_yml(File.join(output_dir, 'yaml_items'))

  cart.delete_items
  
  puts "============================================="

  puts "\n=== ТЕСТУВАННЯ CONFIGURATOR ==="
  
  configurator = MyApplicationNykoliuk::Configurator.new
  puts "Доступні методи (ClassMethod): #{MyApplicationNykoliuk::Configurator.available_methods.join(', ')}"
  puts "Стан за замовчуванням: #{configurator.config}"

  overrides = {
      run_website_parser: 1,      
      run_save_to_csv: 1,         
      run_save_to_yaml: 1,        
      run_save_to_sqlite: 1,     
      non_existent_key: 1 
  }
  configurator.configure(overrides)
  
  puts "\nПеревірка результатів:"
  puts "Поточний стан: #{configurator.config}"
  puts "Парсер включено? #{configurator.run_action?(:run_website_parser)}"
  puts "Збереження в JSON включено? #{configurator.run_action?(:run_save_to_json)}" # Має бути false/0
  puts "============================================="

  web_config_path = File.join(CONFIG_DIR, 'web_parser.yaml') 

  puts "\n=== ЗАПУСК SIMPLE WEBSITE PARSER ==="
  web_config_data = YAML.load_file(web_config_path)
  simple_parser = MyApplicationNykoliuk::SimpleWebsiteParser.new(web_config_data)
  simple_parser.start_parse
  puts "\n✅ SimpleWebsiteParser завершив роботу. Перевірте media/ та output/simple_parser_results."  

  puts "\n✅ Перевірка функціоналу завершена. Перевірте лог-файли в папці logs/."

rescue => e
  puts "\n❌ КРИТИЧНА ПОМИЛКА СИСТЕМИ: #{e.message}"
end