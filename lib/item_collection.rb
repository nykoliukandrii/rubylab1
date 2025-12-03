# item_collection.rb
# frozen_string_literal: true

require 'yaml'
require 'csv'
require_relative 'item_container'
require_relative 'item' 
require_relative 'logger_manager' 

module MyApplicationNykoliuk
  class ItemCollection
    include Enumerable 
    include ItemContainer 
    
    attr_accessor :items 

    def initialize
      @items = []
      MyApplicationNykoliuk::LoggerManager.log_processed_file("ItemCollection (Cart) ініціалізовано.")
    end

    # ----------------------------------------------------
    # МЕТОД ENUMERABLE
    # ----------------------------------------------------

    def each(&block)
      @items.each(&block)
    end
    
    # ----------------------------------------------------
    # ГЕНЕРАЦІЯ ТЕСТОВИХ ДАНИХ
    # ----------------------------------------------------

    def generate_test_items(count)
      count.times do
        add_item(MyApplicationNykoliuk::Item.generate_fake) 
      end
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Згенеровано #{count} тестових Item.")
    end
    
    def items_data
      @items.map(&:to_h) 
    end

    # ----------------------------------------------------
    # МЕТОДИ ЗБЕРЕЖЕННЯ ІНФОРМАЦІЇ
    # ----------------------------------------------------

    def save_to_file(filename)
      File.open(filename, 'w') do |file|
        @items.each { |item| file.puts item.to_s } 
      end
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Колекція збережена у текстовий файл: #{filename}")
    end

    def save_to_json(filename)
      File.write(filename, JSON.pretty_generate(items_data))
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Колекція збережена у JSON: #{filename}")
    end

    def save_to_csv(filename)
      headers = items_data.first&.keys || []
      CSV.open(filename, 'w', col_sep: ';', headers: headers, write_headers: true) do |csv|
        items_data.each { |hash| csv << hash.values }
      end
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Колекція збережена у CSV: #{filename}")
    end

    def save_to_yml(directory)
      FileUtils.mkdir_p(directory)
      @items.each do |item|
        filename = File.join(directory, "#{item.name.gsub(/[^0-9A-Za-z_]/, '_')}_#{item.id.split('-').first}.yml")
        File.write(filename, item.to_h.to_yaml)
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Item збережено у YAML: #{filename}")
      end
    end
    
    # ----------------------------------------------------
    # МЕТОДИ ENUMERABLE (ВИМОГА ЛР - 10 методів)
    # ----------------------------------------------------

    def get_prices
      map(&:price)
    end

    def select_expensive(threshold = 50.0)
      select { |item| item.price.is_a?(Numeric) && item.price > threshold }
    end
    
    def reject_expensive(threshold = 50.0)
      reject { |item| item.price.is_a?(Numeric) && item.price > threshold }
    end

    def find_by_category(category_name)
        find { |item| item.category == category_name }
    end
    
    def total_price
      items_with_price = select { |item| item.price.is_a?(Numeric) }
      items_with_price.reduce(0) { |sum, item| sum + item.price } 
    end
    
    def all_priced?
        all? { |item| item.price.is_a?(Numeric) && item.price > 0 }
    end
    
    def any_expensive?(threshold = 100.0)
        any? { |item| item.price.is_a?(Numeric) && item.price > threshold }
    end
    
    def count_in_category(category_name)
        count { |item| item.category == category_name }
    end
    
    def sort_by_price
        sort
    end
    
    def unique_items
        uniq
    end
  end
end