require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'thwait'
require './db_helper.rb'

class ScrapMediumURL

  include DbHelper

  def initialize
    @@source_url = ['https://medium.com']
    @@thread_size = 5
    @@url_hash = {'https://medium.com' => true}.transform_keys(&:to_sym)
    @@sleep_timer = 2
    @@max_url = 10 #limit the number of urls else the program will run for ever
  end

  #main method to generate all the urls
  def get_urls()
    generate_thread(@@source_url)
  end

  #generate threads from the source url
  def generate_thread(source_url)
    begin
      source_url.each_slice(@@thread_size) do |batch|
        threads = []
        batch.each do |u|
          threads << Thread.new { get_all_links(u) }
        end
        threads.each { |thr| thr.join }
      end
      Thread.list.each do |thread|
        thread.exit unless thread == Thread.current
      end
    rescue Exception => e
      puts "Exception occurred In Thread #{e.message}"
    end
  end

  #get the number of current running threads
  def running_thread_count()
    Thread.list.select {|thread| thread.status == "run"}.count
  end

  def get_all_links(url)
    update_visit_list(url)
    url_list = []
    begin
      puts "FETCHING URL: #{url}"
      sleep @@sleep_timer * 60 # to avoid to many request problem
      url_list = Nokogiri::HTML(open(url).read).css("a").map do |link|
                  if (href = link.attr("href")) && href.match(/^https?:/)
                    href
                  end
                end.compact
    rescue Exception => e
      url_list = []
      puts "Error Fetching URLS #{e.message}"   #mostly because of Error Fetching URLS 429 Too Many Requests
    end
    loop_threads_and_fetch_url(url_list)
  end

  # generate loop and fetch urls
  def loop_threads_and_fetch_url(url_list)
    if @@url_hash.size < @@max_url
      unless url_list.empty?
        if running_thread_count() >= 5
          sleep @@sleep_timer*60
          loop_threads_and_fetch_url(url_list)
        else
          url_list = url_list.map { |url| url if get_host_without_www(url) == 'medium.com' }.compact
          save_data(url_list)
          new_urls_to_scrap = update_url_hash(url_list).compact
          generate_thread(new_urls_to_scrap)
        end
      end
    end
  end

  #get the host name to ensure all urls are from medium
  def get_host_without_www(url)
    url = "http://#{url}" unless url.start_with?('http')
    uri = URI.parse(url)
    host = uri.host.downcase
    host.start_with?('www.') ? host[4..-1] : host
  end

  #update the url hash for all the new urls
  def update_url_hash(url_list)
    url_list.each do |url|
      unless @@url_hash.has_key?(url)
        @@url_hash[url.to_sym] = false
      end
    end
    @@url_hash.collect {|key,value| key.to_s if value == false}
  end

  #update the visited urls
  def update_visit_list(url)
    if @@url_hash.has_key?(url.to_sym)
      @@url_hash[url.to_sym] = true
    else
      puts "Something wend wrong"
    end
  end

  # call the DB and save the data
  def save_data(url_list)
    urls = []
    url_list.each do |url|
      begin
        parsed_url = URI.parse(url)
        main_url = parsed_url.scheme + '://' + parsed_url.host + parsed_url.path
        query = URI::decode_www_form(parsed_url.query).to_h rescue nil
        insert_in_table({url: main_url, query: query})
      rescue Exception => e
        puts "BAD URL = #{e.message}, url = #{url}"
      end
    end
    puts urls
  end

end

scrap_url = ScrapMediumURL.new
scrap_url.drop_table
scrap_url.create_table
scrap_url.get_urls
scrap_url.list_of_all_urls
