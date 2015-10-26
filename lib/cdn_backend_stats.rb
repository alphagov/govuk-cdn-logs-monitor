require_relative 'config'

# Store details of which backends are mostly being used to serve
# requests from the CDN.

$stdin.each_line do |line|
  parsed_logline = parse_logline(line)
  register_backend_hit(parsed_logline[:backend])
end
