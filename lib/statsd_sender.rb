require 'statsd-ruby'

class StatsdSender
  def initialize
    port = ENV['STATSDPORT'] || 8125
    @s = Statsd.new("localhost", port)
    @s.namespace = ENV["GOVUK_STATSD_PREFIX"]
  end

  def increment(name)
    @s.increment(name)
  end
end
