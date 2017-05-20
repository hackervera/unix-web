require "kemal"
require "toml"

config = TOML.parse_file("config.toml")

config.each do |route, handler|
    get route do |env|
        error = IO::Memory.new
        output = IO::Memory.new
        params = env.params.query.map do |k, v|
            "#{k}=\"#{v}\""
        end.join " "
        env.response.content_type = "text/plain"
        process = Process.run(command: handler.to_s, env: env.params.query.to_h, error: error, output: output)
        error.to_s.empty? ?  output.to_s : error.to_s 
    end
end


Kemal.run