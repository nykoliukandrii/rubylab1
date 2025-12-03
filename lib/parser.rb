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

module MyApplicationNykoliuk
  class Parser
    OUTPUT_DIR = 'output'.freeze

    attr_reader :url, :items, :category_selector, :item_selector, :user_agent 

    def initialize(config_file)
      cfg = YAML.load_file(config_file)
      web_cfg = cfg['web_scraping']
      
      @url = web_cfg['start_page']
      @category_selector = web_cfg['category_title_selector']
      @item_selector = web_cfg['item_selector'] 
      @user_agent = web_cfg['user_agent'] 
      @items = []
    end

    def parse_facts
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Старт парсингу: #{url}")
      
      response = fetch_html(url, @user_agent) 
      
      unless response&.success?
        MyApplicationNykoliuk::LoggerManager.log_error("Помилка при отриманні URL: #{url}. Код: #{response&.code}")
        return 
      end
      
      doc = Nokogiri::HTML(response.body)
      category_title = doc.css(@category_selector).text.strip 
      
      @items = doc.css(@item_selector).collect do |item|
        text = item.text.strip
        
        next if text.length <= 5 
        
        {
          id: SecureRandom.uuid,
          category: category_title,
          title: text,
          date_parsed: Time.now.strftime('%Y-%m-%d %H:%M:%S')
        } 
      end.compact
      
      if @items.empty?
        MyApplicationNykoliuk::LoggerManager.log_error("Не знайдено елементів за селектором: #{@item_selector}. Можливо, селектор невірний.")
      end

      save_csv
      save_json
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Завершено. Зібрано елементів: #{@items.size}")
    end

    private
    def fetch_html(target_url, user_agent)
      HTTParty.get(target_url, headers: { 'User-Agent' => user_agent }, timeout: 10 )
    rescue HTTParty::Error => e
      MyApplicationNykoliuk::LoggerManager.log_error("Критична помилка HTTParty: #{e.message}")
      nil
    end

    def save_csv
      FileUtils.mkdir_p(OUTPUT_DIR)
      headers = @items.first&.keys || ['title'] 
      CSV.open(File.join(OUTPUT_DIR, 'facts.csv'), 'w', col_sep: ';', headers: headers, write_headers: true) do |csv|
        @items.each { |item| csv << item.values }
      end
      MyApplicationNykoliuk::LoggerManager.log_processed_file('Дані збережені у CSV.')
    end

    def save_json
      FileUtils.mkdir_p(OUTPUT_DIR)
      File.write(File.join(OUTPUT_DIR, 'facts.json'), JSON.pretty_generate(@items))
      MyApplicationNykoliuk::LoggerManager.log_processed_file('Дані збережені у JSON.')
    end
  end
end