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

  class Parser
    OUTPUT_DIR = 'output'.freeze
    LOGS_DIR = 'logs'.freeze
    LOG_FILE = File.join(LOGS_DIR, 'application.log').freeze
    USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'.freeze
    FACT_SELECTOR = 'article li, .post-content li, ul li, ol li'.freeze

    attr_reader :url, :facts

    def initialize(config_file)
      cfg = YAML.load_file(config_file)
      @url = cfg['start_url']
      @facts = []
    end

    def parse_facts
      log("Старт парсингу: #{url}")
      response = fetch_html(url)
      
      if response && response.body.to_s.length < 500
          log("ДІАГНОСТИКА: Відповідь сервера занадто коротка. Можливо, це блокування/порожня сторінка.")
      end
      
      unless response&.success?
        log("Помилка при отриманні URL: #{url}. Код: #{response&.code}")
        return 
      end
      
      doc = Nokogiri::HTML(response.body)
      category_title = doc.css('h1').text.strip

      @facts = doc.css(FACT_SELECTOR).collect do |li|
        text = li.text.strip
        
        next if text.length <= 5 || text.match?(/^\s*[A-Za-z&\s]+\s*$/)
        
        {
          id: SecureRandom.uuid,
          category: category_title,
          fact_text: text,
          date_parsed: Time.now.strftime('%Y-%m-%d %H:%M:%S')
        } 
      end.compact

      save_csv
      save_json
      log("Завершено. Зібрано фактів: #{@facts.size}")
    end

    private
    def fetch_html(target_url)
      HTTParty.get(target_url, headers: { 'User-Agent' => USER_AGENT }, timeout: 10 )
    rescue HTTParty::Error => e
      log("Критична помилка HTTParty: #{e.message}")
      nil
    end

    def save_csv
      FileUtils.mkdir_p(OUTPUT_DIR)
      headers = facts.first&.keys || ['fact_text']
      CSV.open(File.join(OUTPUT_DIR, 'facts.csv'), 'w', col_sep: ';', headers: headers, write_headers: true) do |csv|
        facts.each { |fact| csv << fact.values }
      end
      log('Дані збережені у CSV.')
    end

    def save_json
      FileUtils.mkdir_p(OUTPUT_DIR)
      File.write(File.join(OUTPUT_DIR, 'facts.json'), JSON.pretty_generate(facts))
      log('Дані збережені у JSON.')
    end

    def log(msg)
      FileUtils.mkdir_p(LOGS_DIR)
      File.open(LOG_FILE, 'a') { |f| f.puts("#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}: #{msg}") }
    end
    
  end