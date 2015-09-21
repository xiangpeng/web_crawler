require 'rubygems'
require 'bundler/setup'


require 'rtesseract'
require 'mini_magick'
require 'mechanize'
module MiniMagick
  class Image
    class << self
      def open(file_or_url, ext = nil)
        file_or_url = file_or_url.to_s # Force it to be a String... hell or highwater
        if file_or_url.include?("://")
          require 'open-uri'
          ext ||= File.extname(URI.parse(file_or_url).path)
          self.read(Kernel::open(file_or_url,"User-Agent" => "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36",), ext)
        else
          ext ||= File.extname(file_or_url)
          File.open(file_or_url, "rb") do |f|
            self.read(f, ext)
          end
        end
      end
    end
  end
end

def parse_number(number_url)
  img = MiniMagick::Image.open(number_url)
  img.resize '200x100'   # 放大
  img.colorspace("GRAY") # 灰度化  
  img.monochrome         # 去色
  str = RTesseract.new(img.path, processor: 'mini_magick').to_s # 识别
  File.unlink(img.path)  # 删除临时文件
  if str.nil?
    number_url
  else
    str
  end
end

# parse_number "jcaptcha.jpg"

# parse_number 'http://zhixing.court.gov.cn/search/security/jcaptcha.jpg'

agent = Mechanize.new
agent.user_agent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36"
page = agent.get('http://zhixing.court.gov.cn/search/')
agent.get('http://zhixing.court.gov.cn/search/security/jcaptcha.jpg').save "image_name.jpg"
str = parse_number('image_name.jpg').gsub(/\s/,'')
form = page.forms.last
form.cardNum = '33032519540116531X'
form.j_captcha = str

img_element = page.search(".//img[@id='captchaImg']").first
search_result = agent.submit(form, form.buttons.last)




