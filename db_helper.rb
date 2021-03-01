require 'sqlite3'
module DbHelper

  DB = SQLite3::Database.new 'url_list.db'

  def create_table
    DB.execute <<-SQL
                CREATE TABLE IF NOT EXISTS url_list (
                  url VARCHAR(30),
                  url_count INT,
                  params VARCHAR(255)
                );
              SQL
  end

  def drop_table
    DB.execute <<-SQL
                DROP TABLE IF EXISTS url_list;
              SQL
  end

  def list_of_all_urls
    DB.execute 'SELECT rowid, url, url_count, params FROM url_list' do |row|
      puts row
    end
  end

  def insert_in_table(url_hash={})
    query_params = !url_hash[:query].nil? ? url_hash[:query].keys.join(',') : ''
    begin
      row = DB.execute "select rowid, url_count, params from url_list where url =?", url_hash[:url]
      row = row.flatten
      if row.empty?
          DB.execute "INSERT INTO url_list(url, url_count, params) VALUES (?, ?, ?)", url_hash[:url], 1, query_params
      else
        new_count = row[1] + 1
        new_params = row[2].split(',') + query_params.split(',')
        new_params = new_params.compact.uniq.join(',')
        DB.execute "UPDATE url_list SET url_count =?, params =? where rowid =?", new_count, query_params, row[0]
      end
    rescue SQLite3::Exception => e
      puts "DB Exception occurred #{e}"
    end
  end

end
