require 'sinatra'
require './court_crawler1'
crawler = CourtCrawler.new
get '/court_exec_info' do
  cert_no = params['cert_no']
  # crawler = CourtCrawler.new
  content_type :json
  result = crawler.crawl(cert_no, true)
  result.to_json
end