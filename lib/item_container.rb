# item_container.rb
# frozen_string_literal: true

require_relative 'logger_manager' 

module MyApplicationNykoliuk
  module ItemContainer
    
    # ----------------------------------------------------
    # А. МЕТОДИ КЛАСУ (ClassMethods) - розширюють сам клас
    # ----------------------------------------------------

    module ClassMethods
      @item_collection_count = 0
      
      def self.item_collection_count
        @item_collection_count
      end

      def self.increment_item_collection_count
        @item_collection_count += 1
      end
      
      def class_info
        "Клас: #{self.name}, Версія: 1.0.0 (З ItemContainer)"
      end

      def item_collection_count
        ClassMethods.item_collection_count
      end
    end

    # ----------------------------------------------------
    # B. МЕТОДИ ЕКЗЕМПЛЯРА (InstanceMethods) - додаються до об'єктів
    # ----------------------------------------------------

    module InstanceMethods
      
      def add_item(item)
        unless item.is_a?(MyApplicationNykoliuk::Item)
          MyApplicationNykoliuk::LoggerManager.log_error("ItemContainer Error: Спроба додати не-Item об'єкт.")
          return
        end
        @items << item
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Item додано до колекції: #{item.name}")
      end

      def remove_item(item)
        if @items.delete(item)
          MyApplicationNykoliuk::LoggerManager.log_processed_file("Item видалено з колекції: #{item.name}")
          return item
        else
          MyApplicationNykoliuk::LoggerManager.log_error("ItemContainer Error: Об'єкт #{item.name} не знайдено для видалення.")
          return nil
        end
      end
      
      def delete_items
        count = @items.size
        @items.clear
        MyApplicationNykoliuk::LoggerManager.log_processed_file("Всі #{count} елементів видалені з колекції.")
      end
      
      def method_missing(method_name, *args, &block)
        if method_name.to_s == 'show_all_items'
          MyApplicationNykoliuk::LoggerManager.log_processed_file("Викликано show_all_items через method_missing.")
          puts "\n=== Усі елементи колекції (#{@items.size}) ==="
          @items.each { |item| puts item.info } 
          puts "=============================================="
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s == 'show_all_items' || super
      end
    end

    # ----------------------------------------------------
    # C. CALLBACK-МЕТОД (self.included) - механізм підмішування
    # ----------------------------------------------------

    def self.included(base)
      base.extend ClassMethods     
      base.include InstanceMethods 
      
      MyApplicationNykoliuk::LoggerManager.log_processed_file("Модуль ItemContainer підмішано до класу #{base.name}")
      
      ClassMethods.increment_item_collection_count
    end
  end
end