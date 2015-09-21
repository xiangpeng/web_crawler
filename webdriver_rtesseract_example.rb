require 'rubygems'
require 'bundler/setup'


require 'rtesseract'
require 'mini_magick'
require 'watir-webdriver'
require 'watir/extensions/element/screenshot'


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

browser = Watir::Browser.new :phantomjs
browser.goto 'http://zhixing.court.gov.cn/search/'
browser.img(id: 'captchaImg').screenshot('cap.jpg')
