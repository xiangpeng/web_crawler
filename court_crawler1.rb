require 'active_record'
require 'pg'
require 'digest/md5'
require 'rest-client'
require 'nokogiri'
require './model'
ActiveRecord::Base.establish_connection(:adapter => "postgresql", :database  => "crawler_db", host: "localhost", user_name: 'xiangpeng', pool: 100)

class CourtCrawler
  def crawl(cert_no, save_flag=false)
    begin
      html_str = RestClient.post "http://zhixing.court.gov.cn/search/search", {searchCourtName:'全国法院（包含地方各级法院）',selectCourtId:1,selectCourtArrange:1,pname:"",cardNum:cert_no,j_captcha:'99999'}, user_agent: 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36'
    rescue RestClient::ResourceNotFound => e
      return {}
    end
    result_arr = []
    html_doc = Nokogiri::HTML(html_str)
    html_doc.css("#Resultlist a:contains('查看')").each do |i|
      id = i.attr('id')
      item = get_detail  "http://zhixing.court.gov.cn/search/detail?id=#{id}"
      puts "#{cert_no}:#{item}"
      md5 = Digest::MD5.hexdigest("#{item[:name]}#{item[:ourt_name]}#{item[:create_time]}#{item[:case_code]}#{item[:case_state]}#{item[:exec_money]}")
      puts md5
      CourtExecInfo.create(item.merge(cert_no: cert_no, crawl_date: Date.current, md5: md5)) if save_flag
      result_arr << item.merge(cert_no: cert_no, crawl_date: Date.current, md5: md5)
    end
    return result_arr
  end

  def get_detail(url)
    page = RestClient.get url, user_agent: 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36'
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
  end
end


