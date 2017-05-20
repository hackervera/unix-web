require "kemal"
require "toml"

config = TOML.parse_file("config.toml")
config.each do |route, handler|
    get route do |env|
        params = env.params.query.map do |k, v|
            "#{k}=#{v}"
        end.join " "
        `#{params} #{handler}`
    end
end


Kemal.run