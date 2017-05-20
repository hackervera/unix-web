require "xml"
require "db"
require "pg"
require "digest"
require "http"

DbUrl = "postgres://127.0.0.1/feeds"

Conn = begin
    DB.open DbUrl
rescue
    raise "Need to create database named #{DbUrl}"
end

# Conn = DB.open DbUrl

Urls = if urls = ENV["URLS"]?
    urls.split(",")
else
    [] of String
end

# FeedUrls = [
#   "https://www.wired.com/feed/",
#   "https://www.theatlantic.com/feed/all/",
#   "http://readwrite.com/feed/",
#   "https://lobste.rs/rss?token=r2nOOrbCZKC2dSbLAL0kLSYGJ4U5jE8Pe4PmHyLDhtuSyimsQWRCqyMYCeVM",
#   "https://news.ycombinator.com/rss",
#   "http://fetchrss.com/rss/58dd6e848a93f8b2758b4568953711301.atom",
#   "http://www.economist.com/sections/united-states/rss.xml",
#   "http://www.aljazeera.com/xml/rss/all.xml",
# ]

begin
  Conn.exec "create table items (
    title text,
    link text,
    guid text,
    date timestamp,
    primary key (guid)

)"
rescue
    #Table exists
end

Urls.map do |feed_url|
  future { Feed.new(feed_url) }
end.map do |f|
  f.get
end

Conn.query "select link,title from items order by date desc limit 50" do |rs|
  rs.each do
    if ENV["FMT"]? == "text/html"
        puts "<div><a href=#{rs.read(String)}>#{rs.read(String)}</a></div>"
    else
        link = rs.read(String)
        title = rs.read(String)
        puts "#{title} #{link}"
    end
  end
end

class Feed
  record Item, title : String, link : String, date : Time, guid : String

  def initialize(url)
    res = HTTP::Client.get(url).body
    document = XML.parse(res)
    parse_document(document)
  end

  def parse_document(document)
    items = document.xpath("//channel//item").as(XML::NodeSet)
    items2 = items
    if !items.empty?
      items.map do |node|
        title = node.xpath_node("title").as(XML::Node).content
        link = node.xpath("link").as(XML::NodeSet).first.content
        date = Time.parse(node.xpath("pubDate").as(XML::NodeSet).first.content, "%a, %d %b %Y %T %z")
        content = (node.xpath_node("description").as(XML::Node)).content
        guid_node = node.xpath_node("guid")
        if guid_node.nil?
          guid = Digest::SHA1.hexdigest(content)
        else
          guid = guid_node.as(XML::Node).content
        end
        item = Item.new(title, link, date, guid)
        begin
          Conn.exec "insert into items values ($1, $2, $3, $4)", title, link, guid, date
          item
        rescue e : PQ::PQError
          #   STDERR.puts e.message
        end
      end
      return
    end
    items = document.xpath("//atom:entry", {"atom" => "http://www.w3.org/2005/Atom"}).as(XML::NodeSet)
    if !items.empty?
      items.map do |node|
        guid = node.xpath_node("atom:id", {"atom" => "http://www.w3.org/2005/Atom"}).as(XML::Node).content
        title = node.xpath_node("atom:title", {"atom" => "http://www.w3.org/2005/Atom"}).as(XML::Node).content
        link = node.xpath_node("atom:link", {"atom" => "http://www.w3.org/2005/Atom"}).as(XML::Node)["href"]
        date_content = case x = node.xpath_node("atom:published", {"atom" => "http://www.w3.org/2005/Atom"})
                       when XML::Node
                         x.content
                       when Nil
                         #  puts node.inspect
                         nil
                       end
        if date_content
          date = Time.parse(date_content, "%FT%X%z")
        else
          date = Time.now
        end
        categories = [] of String
        content = node.xpath_node("atom:content", {"atom" => "http://www.w3.org/2005/Atom"}).as(XML::Node).content
        item = Item.new(title, link, date, guid)
        begin
          Conn.exec "insert into items values ($1, $2, $3, $4)", title, link, guid, date
          item
        rescue e : PQ::PQError
          #   STDERR.puts e.message
        end
      end
    end
  end
end
