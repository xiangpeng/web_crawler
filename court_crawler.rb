require 'active_record'
require 'pg'
require 'digest/md5'
require './model'
ActiveRecord::Base.establish_connection(:adapter => "postgresql", :database  => "crawler_db", host: "localhost", user_name: 'xiangpeng')

class CourtCrawler
  attr_accessor :browser, :data_agent
  def initialize
    @data_agent = Mechanize.new
    @data_agent.user_agent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36"
    @browser = Watir::Browser.new :firefox
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
        alert_text = @browser.alert.text
        @browser.alert.ok
        sleep 1
        break if alert_text.include? '组织结构代码不合法'
        next
      else
        rows = @browser.iframe(index: 0).table(id: 'Resultlist').rows
        puts "#{cert_no}    #{rows.count}"
        if(rows.count > 1)
          rows[1..-1].each do |row|
            item = get_detail "http://zhixing.court.gov.cn/search/detail?id=#{row.links[-1].id}"
            puts item
            md5 = Digest::MD5.hexdigest("#{item[:name]}#{item[:ourt_name]}#{item[:create_time]}#{item[:case_code]}#{item[:case_state]}#{item[:exec_money]}")
            puts md5
            CourtExecInfo.create(item.merge(cert_no: cert_no, crawl_date: Date.current, md5: md5))
          end
        end
        sleep 1
        break
      end
    end
  end

  def get_detail(url)
    page = @data_agent.get url
    result = JSON.parse page.body
    {
      name: result['pname'], 
      court_name: result['execCourtName'],
      create_time: result['caseCreateTime'],
      case_code: result['caseCode'],
      case_state: result['caseState'],
      exec_money: result['execMoney']
   }
  end

  def close
    @browser.quit
  end
end


