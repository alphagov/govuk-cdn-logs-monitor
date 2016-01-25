require 'uri'
require 'json'

class LogstashSender
  def log(logline, tags, last_success)
    $stdout.puts logstash_format_json(logline, tags, last_success)
  end

private
  def logstash_format_json(logline, tags, last_success)
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
        "last_success" => last_success
      },
      "@tags" => tags,
      "@timestamp" => logline.time.iso8601,
      "@version" => "1"
    })
  end
end
