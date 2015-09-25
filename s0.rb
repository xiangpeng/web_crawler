require 'rubygems'
require 'bundler/setup'


require 'rtesseract'
require 'mini_magick'
require 'mechanize'
require 'watir-webdriver'
require 'watir/extensions/element/screenshot'
require 'securerandom'
require 'sidekiq'
require './court_crawler'
# If your client is single-threaded, we just need a single connection in our Redis connection pool
Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'crawler', :size => 1 }
end

# Sidekiq server is multi-threaded so our Redis connection pool size defaults to concurrency (-c)
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'crawler' }
end
