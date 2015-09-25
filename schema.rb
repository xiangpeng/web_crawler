require 'active_record'
require 'pg'
ActiveRecord::Base.establish_connection(:adapter => "postgresql", :database  => "crawler_db", host: "localhost", user_name: 'xiangpeng')
ActiveRecord::Schema.define do
  drop_table :cust_infos if table_exists? :cust_infos
  create_table :cust_infos do |table|
    table.column :cust_no, :string
    table.column :cert_no, :string
  end

  drop_table :court_exec_infos if table_exists? :court_exec_infos
  create_table :court_exec_infos do |table|
    table.column :cert_no, :string
    table.column :name,    :string
    table.column :court_name, :string
    table.column :create_time, :string
    table.column :case_code, :string
    table.column :case_state, :string
    table.column :exec_money, :string
    table.column :crawl_date, :date
    table.column :md5,        :string
  end
  add_index :court_exec_infos, :md5, name: 'idx_md5_court_exec_infos', unique: true
end

