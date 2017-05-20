# require "./speed/*"

# module Speed
#   # TODO Put your code here
# end

require "http"

macro build_requests(urls)
  parallel(
    {% for url in urls %}
      HTTP::Client.get({{url}}).headers,
    {% end %}
  )
end

class UrlConcurrency
  @responses : Array(Concurrent::Future(HTTP::Client::Response))

  def initialize(urls)
    @responses = urls.map do |url|
      future { HTTP::Client.get(url) }
    end
  end

  def responses
    @responses.map(&.get)
  end
end

p UrlConcurrency.new(%w{http://mashable.com http://google.com}).responses
