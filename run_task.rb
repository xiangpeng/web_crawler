require 'sidekiq'
require 'active_record'
require 'pg'
require './model'
ActiveRecord::Base.establish_connection(:adapter => "postgresql", :database  => "crawler_db", host: "localhost", user_name: 'xiangpeng')
cert_no_arr = CustInfo.pluck(:cert_no).in_groups(4)
cert_no_arr.each_with_index do |arr, index|
  (arr.compact).in_groups_of(500).each {|i| Sidekiq::Client.push 'class'=> 'CrawlerWorker', 'args'=> [i.compact], 'queue'=> "crawler#{index}" }
end