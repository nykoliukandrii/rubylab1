# lib/logger_manager.rb
require 'logger'
require 'fileutils'

module MyApplicationNykoliuk
  class LoggerManager
    class << self
      attr_reader :logger, :error_logger
      
      def configure(config)
        log_cfg = config['logging']
        
        log_dir = log_cfg['directory']
        FileUtils.mkdir_p(log_dir)

        level = Logger::Severity.const_get(log_cfg['level'].upcase) rescue Logger::INFO

        app_log_file = File.join(log_dir, log_cfg['files']['application_log'])
        @logger = Logger.new(app_log_file, 5, 10 * 1024 * 1024)
        @logger.level = level
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
        end

        error_log_file = File.join(log_dir, log_cfg['files']['error_log'])
        @error_logger = Logger.new(error_log_file)
        @error_logger.level = Logger::ERROR
      end

      def log_processed_file(msg)
        @logger.info(msg) if @logger
      end

      def log_error(msg)
        @error_logger.error(msg) if @error_logger
      end
    end
  end
end