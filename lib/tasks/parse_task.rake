# frozen_string_literal: true

require_relative '../parser'

task :parse do
  parser = Parser.new('config/application.yml')
  parser.parse_facts
  puts 'Rake task: парсинг завершено!'
end
