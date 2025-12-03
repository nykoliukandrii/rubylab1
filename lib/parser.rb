# frozen_string_literal: true

require 'yaml'
require 'csv'
require 'json'
require 'fileutils'
require 'time'
require 'nokogiri'
require 'httparty'

class Parser
  OUTPUT_DIR = 'output'.freeze
  LOGS_DIR = 'logs'.freeze
  LOG_FILE = File.join(LOGS_DIR, 'application.log').freeze
  USER_AGENT = 'Mozilla/5.0 (compatible; Ruby Scraper)'.freeze
  
  attr_reader :url, :facts

  def initialize(config_file)
    cfg = YAML.load_file(config_file)
    @url = cfg['start_url']
    @facts = []
  end

  def parse_facts
    log("Старт парсингу: #{url}")

    response = fetch_html(url)

    unless response&.success?
      log("Помилка при отриманні URL: #{url}. Код: #{response&.code}")
      return
    end

    doc = Nokogiri::HTML(response.body)
    
    @facts = doc.css('ol li, ul li').collect do |li|
      text = li.text.strip
      text.length > 5 ? text : nil 
    end.compact

    save_csv
    save_json

    log("Завершено. Зібрано фактів: #{@facts.size}")
  end

  private

  def fetch_html(target_url)
    HTTParty.get(
      target_url,
      headers: { 'User-Agent' => USER_AGENT },
      timeout: 10 
    )
  rescue HTTParty::Error => e
    log("Критична помибка HTTParty: #{e.message}")
    nil
  end

  def save_csv
    FileUtils.mkdir_p(OUTPUT_DIR)
    CSV.open(File.join(OUTPUT_DIR, 'facts.csv'), 'w', col_sep: ';') do |csv|
      facts.each { |fact| csv << [fact] }
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