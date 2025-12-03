# lib/item.rb
# frozen_string_literal: true

require 'faker'
require 'securerandom'

module MyApplicationNykoliuk
  class Item
    include Comparable 
    
    attr_accessor :name, :price, :description, :category, :image_path, :id

    DEFAULTS = {
      id: SecureRandom.uuid,
      name: 'Невідомий товар',
      price: 0.0,
      description: 'Опис відсутній',
      category: 'Без категорії',
      image_path: 'images/default.jpg' 
    }.freeze

    def initialize(params = {})
      merged_params = DEFAULTS.merge(params)

      merged_params.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end

      yield self if block_given?

      LoggerManager.log_processed_file("Item створено: ID #{self.id}, Name: #{self.name}")
    rescue StandardError => e
      LoggerManager.log_error("Помилка ініціалізації Item: #{e.message}")
    end

    def to_s
      output = "--- Item Info ---\n"
      self.instance_variables.each do |attr|
        key = attr.to_s.delete('@')
        output += "#{key.capitalize.ljust(12)}: #{self.instance_variable_get(attr)}\n"
      end
      output += "-----------------"
      output
    end

    alias_method :info, :to_s

    def to_h
      hash = {}
      self.instance_variables.each do |attr|
        key = attr.to_s.delete('@').to_sym
        hash[key] = self.instance_variable_get(attr)
      end
      hash
    end

    def inspect
      "#<#{self.class.name} ID:#{self.id} Name:'#{self.name}' Price:#{self.price}>"
    end

    def update
      if block_given?
        yield self
        LoggerManager.log_processed_file("Item оновлено: ID #{self.id}")
      else
        LoggerManager.log_error("Item update error: Блок не передано.")
      end
    end

    def <=>(other)
      return unless other.is_a?(Item)
      self.price <=> other.price
    end

    def self.generate_fake
      Item.new(
        name: Faker::Book.title,
        price: Faker::Number.between(from: 10.0, to: 500.0).round(2),
        description: Faker::Lorem.paragraph(sentence_count: 2),
        category: Faker::Book.genre,
        image_path: "images/#{Faker::Lorem.word}.jpg"
      )
    end
  end
end