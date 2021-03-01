# medium-web-scrapper-using-ruby
Recursively crawl popular blogging website
https://medium.com using Ruby and harvest all 
possible hyperlinks that belong to medium.com and store them in a database of your choice

## To run Application locally

clone the project run the below command

```bash
use ruby 2.7
sqlite DB has been used
$ gem install nokogiri
$ ruby scrap_medium_url.rb // to run ruby program
```

## Configurations
```bash
@@sleep_timer = 2 # value*60 seconds
@@max_url = 10 #max number of urls , put a higher value in you want to scrap more
@@retry_counter = 0 # currently only one retry
```

use sqlite editor to view the data which will be generated
as user_list.db
or use https://sqliteonline.com/ 