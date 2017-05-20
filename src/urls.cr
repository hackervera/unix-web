require "http"
urls = ENV["URLS"].split(",")
headers = urls.map do |url|
    future{ HTTP::Client.get(url).headers }
end.map do |f|
    f.get
end
puts headers