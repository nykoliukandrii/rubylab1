# frozen_string_literal: true

task :clean do
  puts 'Видалення логів та вихідних файлів...'
  FileUtils.rm_f('logs/application.log')
  FileUtils.rm_rf('output')
  puts 'Очищення завершено.'
end

task default: :parse