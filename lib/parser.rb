# lib/parser.rb
# frozen_string_literal: true

require 'yaml'
require 'csv'
require 'json'
require 'fileutils'
require 'time'
require 'nokogiri'
require 'httparty'
require 'securerandom'
require 'uri' 

module MyApplicationNykoliuk
  class Parser
    OUTPUT_DIR = 'output'.freeze

    attr_reader :url, :items, :category_selector, :item_selector, :user_agent, :category_link_selector

    def initialize(config_file)
      cfg = YAML.load_file(config_file)
      web_cfg = cfg['web_scraping']
      
      @url = web_cfg['start_page']
      @category_selector = web_cfg['category_title_selector']
      @item_selector = web_cfg['item_selector'] 
      @user_agent = web_cfg['user_agent'] 
      @category_link_selector = web_cfg['category_link_selector']
      @items = [] 
    end

    def parse_all_categories
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Старт збору категорій з: #{@url}")

        response = fetch_html(@url, @user_agent)
        unless response&.success?
            MyApplicationNykoliuk::LoggerManager.log_error("Помилка при отриманні головної URL: #{@url}")
            return
        end

        doc = Nokogiri::HTML(response.body)
        
        category_links = doc.css(@category_link_selector).map do |link|
            full_url = URI.join(@url, link['href']).to_s
            { name: link.text.strip, url: full_url }
        end.compact
        
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Знайдено #{category_links.size} категорій для парсингу.")
        
        if category_links.empty?
             MyApplicationNykoliuk::LoggerManager.log_error("Не знайдено жодних посилань на категорії за селектором: #{@category_link_selector}")
             return
        end
        
        category_links.take(5).each { |cat| puts "✅ Знайдена категорія: #{cat[:name]}" }
        
        all_parsed_items_count = 0

        category_links.each do |category|
            data = parse_category_page(category[:url]) 
            
            if data && data[:collection].is_a?(MyApplicationNykoliuk::ItemCollection)
                collection_size = data[:collection].items.size
                
                save_category_data(data[:category], data[:collection])
                all_parsed_items_count += collection_size
            end
        end
        
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Завершено парсинг всіх категорій. Загальна кількість зібраних книг: #{all_parsed_items_count}.")
    end

    private
    
    def parse_category_page(category_url)
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Старт парсингу сторінки: #{category_url}")
        
        response = fetch_html(category_url, @user_agent)
        unless response&.success?
            MyApplicationNykoliuk::LoggerManager.log_error("Помилка при отриманні URL категорії: #{category_url}")
            return nil
        end

        doc = Nokogiri::HTML(response.body)
        
        category_title = doc.css(@category_selector).text.strip

        collection = MyApplicationNykoliuk::ItemCollection.new
        
        doc.css(@item_selector).each do |item_element|
            title = item_element.text.strip
            next if title.length <= 5
            
            item = MyApplicationNykoliuk::Item.new(
              name: title,
              category: category_title,
              price: 0.0, 
              description: 'Тимчасовий опис',
              image_path: 'N/A'
            )
            collection.add_item(item) 
        end
        
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Зібрано #{collection.items.size} книг у категорії '#{category_title}'.")
        
        return { 
          category: category_title,
          collection: collection 
        }
    end

    def save_category_data(category_name, item_collection)
        dir_name = File.join(OUTPUT_DIR, category_name.gsub(/\s+/, '_').gsub(/[^0-9A-Za-z_]/, '')) 
        FileUtils.mkdir_p(dir_name)

        json_filename = File.join(dir_name, "items.json")
        item_collection.save_to_json(json_filename)
        
        csv_filename = File.join(dir_name, "items.csv")
        item_collection.save_to_csv(csv_filename)
        
        yml_dir = File.join(dir_name, "yaml_items")
        item_collection.save_to_yml(yml_dir) 
        
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Категорія '#{category_name}' збережена у #{dir_name} через ItemCollection.")
    end
    
    def fetch_html(target_url, user_agent)
      HTTParty.get(target_url, headers: { 'User-Agent' => user_agent }, timeout: 10 )
    rescue HTTParty::Error => e
      MyApplicationNykoliuk::LoggerManager.log_error("Критична помилка HTTParty: #{e.message}")
      nil
    end
  end
end