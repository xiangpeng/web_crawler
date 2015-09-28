require 'rubygems'
require 'bundler/setup'


require 'rtesseract'
require 'mini_magick'
require 'mechanize'
require 'watir-webdriver'
require 'watir/extensions/element/screenshot'
require 'securerandom'
require 'sidekiq'
require './court_crawler1'
# If your client is single-threaded, we just need a single connection in our Redis connection pool
Sidekiq.configure_client do |config|
  # config.redis = { :namespace => 'crawler', :size => 1 }
end

# Sidekiq server is multi-threaded so our Redis connection pool size defaults to concurrency (-c)
Sidekiq.configure_server do |config|
  # config.redis = { :namespace => 'crawler' }
  config.error_handlers << Proc.new {|ex,ctx_hash| Sidekiq::Client.push 'class'=> CrawlerWorker, 'args'=> ctx_hash['args'], 'queue'=> ctx_hash['queue'] }
end


class CrawlerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false 
  def perform(cert_no_arr)
    crawler = CourtCrawler.new
    begin
      cert_no_arr.each do |cert_no|
        crawler.crawl cert_no
      end
      crawler.close
    rescue Exception => e
      crawler.close
      raise
    end
    
  end
end
