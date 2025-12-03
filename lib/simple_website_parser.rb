# lib/simple_website_parser.rb
# frozen_string_literal: true

require 'yaml'
require 'nokogiri'
require 'httparty'
require 'uri'
require 'fileutils'
require_relative 'item_collection'
require_relative 'logger_manager'
require_relative 'item'

module MyApplicationNykoliuk
  class SimpleWebsiteParser
    OUTPUT_DIR = 'output'.freeze
    MEDIA_DIR = 'media'.freeze
    
    attr_reader :config, :item_collection, :base_url, :user_agent
    
    def initialize(config)
      @config = config['web_scraping']
      @base_url = @config['start_page']
      @user_agent = @config['user_agent']
      @item_collection = MyApplicationNykoliuk::ItemCollection.new
      
      FileUtils.mkdir_p(MEDIA_DIR)
      FileUtils.mkdir_p(OUTPUT_DIR)
      
      MyApplicationNykoliuk::LoggerManager.log_processed_file("SimpleWebsiteParser ініціалізовано. URL: #{@base_url}")
    end

    def start_parse
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Старт парсингу (SimpleWebsiteParser).")
      
      response = fetch_html(@base_url)
      unless response&.success?
        MyApplicationNykoliuk::LoggerManager.log_error("Помилка при отриманні головної URL: #{@base_url}")
        return
      end

      doc = Nokogiri::HTML(response.body)
      
      product_links = extract_products_links(doc)
      
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Знайдено #{product_links.size} продуктів для детального парсингу.")

      threads = []
      product_links.each do |link|
        threads << Thread.new { parse_product_page(link) }
      end
      
      threads.each(&:join)

      save_all_data
      
      MyApplicationNykoliuk::LoggerManager.log_processed_file("SimpleWebsiteParser завершив роботу. Зібрано #{@item_collection.items.size} товарів.")
    end

    private
    
    def fetch_html(target_url)
      response = HTTParty.get(target_url, headers: { 'User-Agent' => @user_agent }, timeout: 10 )
      response
    rescue HTTParty::Error => e
      MyApplicationNykoliuk::LoggerManager.log_error("Критична помилка HTTParty для #{target_url}: #{e.message}")
      nil
    end
    
    def extract_products_links(page)
      page.css(@config['item_link_selector']).map do |link|
        URI.join(@base_url, link['href']).to_s
      end.compact.uniq
    end

    def parse_product_page(product_link)
      unless check_url_response(product_link)
        MyApplicationNykoliuk::LoggerManager.log_error("URL недоступний: #{product_link}")
        return
      end
      
      response = fetch_html(product_link)
      return unless response&.success?
      
      doc = Nokogiri::HTML(response.body)
      
      name = extract_product_name(doc)
      price = extract_product_price(doc)
      description = extract_product_description(doc)
      image_url = extract_product_image(doc)
      category = extract_product_category(doc)
      
      image_path = download_image(name, category, image_url)
      
      item = MyApplicationNykoliuk::Item.new(
        name: name,
        category: category,
        price: price,
        description: description,
        image_path: image_path
      )
      @item_collection.add_item(item)
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Товар успішно зібрано: #{name} (Ціна: #{price})")
    end

    def check_url_response(url)
      response = fetch_html(url)
      response&.success? || false
    end
    
    def extract_product_name(page)
      page.css(@config['name_selector']).text.strip
    end

    def extract_product_price(page)
      price_element = page.css(@config['price_selector']).first
      
      if price_element
        price_text = price_element.text.strip
        
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Діагностика ціни: Знайдений текст: '#{price_text}'")
        
        match_data = price_text.match(/(\d+\.?\d+)/)
        
        return match_data ? match_data[0].to_f : 0.0
      else
        MyApplicationNykoliuk::LoggerManager.log_error("Селектор ціни (#{@config['price_selector']}) НЕ ЗНАЙШОВ елемент.")
        return 0.0
      end
    rescue => e
      MyApplicationNykoliuk::LoggerManager.log_error("Критична помилка парсингу ціни: #{e.message}")
      return 0.0
    end

    def extract_product_description(page)
      page.css(@config['description_selector']).first&.text&.strip || 'Опис відсутній'
    end
    
    def extract_product_category(page)
      page.css('ul.breadcrumb li a').map(&:text).compact.last || 'Uncategorized'
    end

    def extract_product_image(page)
      image_element = page.css(@config['image_selector']).first 
      if image_element
        relative_url = image_element['src']
        return URI.join(@base_url, relative_url).to_s
      else
        return 'N/A' 
      end
    end
    
    def download_image(item_name, category, image_url)
      return 'N/A' unless image_url =~ URI::DEFAULT_PARSER.make_regexp
      
      clean_category = category.gsub(/\s+/, '_').gsub(/[^0-9A-Za-z_]/, '')
      category_dir = File.join(MEDIA_DIR, clean_category)
      FileUtils.mkdir_p(category_dir)
      
      image_filename = "#{item_name.gsub(/\s+/, '_').gsub(/[^0-9A-Za-z_]/, '')}.jpg"
      file_path = File.join(category_dir, image_filename)

      response = HTTParty.get(image_url)
      
      if response.success?
        File.open(file_path, 'wb') { |file| file.write(response.body) }
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Зображення збережено: #{file_path}")
        return file_path
      else
        MyApplicationNykoliuk::LoggerManager.log_error("Помилка при завантаженні зображення з: #{image_url}")
        return 'N/A'
      end
    rescue => e
      MyApplicationNykoliuk::LoggerManager.log_error("Критична помилка при збереженні зображення: #{e.message}")
      return 'N/A'
    end
    
    def save_all_data
      base_dir = OUTPUT_DIR
      
      items_by_category = @item_collection.items.group_by(&:category)
      
      items_by_category.each do |category, items|
        clean_category = category.gsub(/\s+/, '_').gsub(/[^0-9A-Za-z_]/, '')
        
        category_dir = File.join(base_dir, clean_category) 
    FileUtils.mkdir_p(category_dir)
        
        temp_collection = MyApplicationNykoliuk::ItemCollection.new
        items.each { |item| temp_collection.add_item(item) }
        
        json_path = File.join(category_dir, 'items.json')
        temp_collection.save_to_json(json_path)
        
        csv_path = File.join(category_dir, 'items.csv')
        temp_collection.save_to_csv(csv_path)
        
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Дані для категорії '#{category}' збережено у #{category_dir}.")
      end
    end
  end
end