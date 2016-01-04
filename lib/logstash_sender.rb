require 'uri'
require 'json'

class LogstashSender
  def log(logline, type)
    $stdout.puts logstash_format_json(logline, type)
  end

private
  def logstash_format_json(logline, tags)
    uri = URI.parse(logline.path)
    JSON.generate({
      "@fields" => {
        "method" => logline.method,
        "path" => uri.path,
        "query_string" => uri.query,
        "status" => logline.status.to_i,
        "remote_addr" => logline[0],
        "request" => "#{logline.method} #{logline.path}",
        "cdn_backend" => logline.cdn_backend,
        "length" => "-"},
        "@tags" => tags,
        "@timestamp" => logline.time.iso8601,
        "@version" => "1"
    })
  end
end
