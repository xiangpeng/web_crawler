require 'rubygems'
require 'bundler/setup'


require 'rtesseract'
require 'mini_magick'
require 'mechanize'
require 'watir-webdriver'
require 'watir/extensions/element/screenshot'
require 'securerandom'
require 'sidekiq'

# If your client is single-threaded, we just need a single connection in our Redis connection pool
Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'crawler', :size => 1 }
end

# Sidekiq server is multi-threaded so our Redis connection pool size defaults to concurrency (-c)
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'crawler' }
end

# browser = Watir::Browser.new :phantomjs


class CourtCrawler
  attr_accessor :browser, :data_agent
  def initialize
    @data_agent = Mechanize.new
    @data_agent.user_agent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36"
    @browser = Watir::Browser.new :chrome
    @browser.goto 'http://zhixing.court.gov.cn/search/'
  end

  def parse_number(number_url)
    img = MiniMagick::Image.open(number_url)
    str = RTesseract.new(img.path, processor: 'mini_magick').to_s # 识别
    File.unlink(img.path)  # 删除临时文件
    if str.nil?
      number_url
    else
      str
    end
  end

  def crawl(cert_no)
    5.times do
      file_name = "./temp_img/#{SecureRandom.uuid}.jpg"
      @browser.img(id: 'captchaImg').screenshot(file_name)
      cap_str = parse_number(file_name).gsub(/\s/,'')
      @browser.text_field(id: 'cardNum').set cert_no
      @browser.text_field(id: 'j_captcha').set cap_str
      @browser.button(id: 'button').click
      if @browser.alert.exists?
        @browser.alert.ok
        sleep 1
        next
      else
        rows = @browser.iframe(index: 0).table(id: 'Resultlist').rows
        puts rows.count
        if(rows.count > 1)
          rows[1..-1].each do |row|
            puts get_detail "http://zhixing.court.gov.cn/search/detail?id=#{row.links[-1].id}"
          end
        end
        break
      end
    end
  end

  def get_detail(url)
    page = @data_agent.get url
    return JSON.parse page.body
  end

  def close
    @browser.quit
  end
end



class CrawlerWorker
  include Sidekiq::Worker
  def perform(cert_no_arr)
    crawler = CourtCrawler.new
    cert_no_arr.each do |cert_no|
      crawler.crawl cert_no
    end
    crawler.close
  end
end

