require 'rubygems'
require 'bundler/setup'


require 'rtesseract'
require 'mini_magick'
require 'watir-webdriver'
require 'watir/extensions/element/screenshot'
require 'securerandom'

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

# browser = Watir::Browser.new :phantomjs
browser = Watir::Browser.new :chrome
browser.goto 'http://zhixing.court.gov.cn/search/'
file_name = "#{SecureRandom.uuid}.jpg"
browser.img(id: 'captchaImg').screenshot(file_name)
cap_str = parse_number(file_name).gsub(/\s/,'')
browser.text_field(id: 'cardNum').set '33032519540116531X'
browser.text_field(id: 'j_captcha').set cap_str
browser.button(id: 'button').click
browser.iframe(index: 0).table(id: 'Resultlist')
