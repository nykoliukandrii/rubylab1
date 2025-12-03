# frozen_string_literal: true

require_relative 'parser'

parser = Parser.new('config/application.yml')
parser.parse_facts
puts 'Парсинг завершено! Факти збережені у output/facts.csv та output/facts.json'
