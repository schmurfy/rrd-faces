#!/usr/bin/env ruby1.9

# this file is designed to be run by collectd by:
# <Plugin exec>
#   NotificationExec "user" "/path/to/handle_alerts.rb"
# </Plugin>
#
# input time are supposed to be in GMT
#
# alerts will be logged in file and emails will be sent
# to each configured recipients
#

begin
  # Require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
  require "bundler"
  Bundler.setup
end

Bundler.require(:default, :notifications)

require 'logger'
require 'yaml'


module Config
  def self._data
    @config ||= YAML.parse_file( File.join(File.dirname(__FILE__), 'config/alerts_conf.yml') )
  end
  
  def self.timezone
    @tz ||= TZInfo::Timezone.get(_data['timezone'].value)
  end
  
  def self.email_recipients
    @email_list ||= _data['emails']['recipients'].value.map(&:value)
  end
  
  def self.from_email
    @email_from ||= _data['emails']['from'].value
  end
  
  def self.smtp_host
    @smtp_host ||= _data['emails']['host'].value
  end
  
  
  
  def self.logger
    log_file = Config._data['logger']['path'].value
    @logger ||= Logger.new( STDOUT )
  end
end

MmMail::Transport::DefaultConfig.host = Config::smtp_host

def send_email(subject, body)
  Config::email_recipients.each do |recipient|
    MmMail.mail(
        :to       => recipient,
        :from     => Config::from_email,
        :subject  => subject,
        :body     => body,
      )
    end
end

class Notification
  
  FLOAT_VALUES = [:value, :warn_min, :warn_max, :failure_min, :failure_max].freeze
  
  attr_accessor :severity, :time, :host, :plugin, :plugin_instance, :type, :type_instance, :datasource, :value,
    :warn_min, :warn_max, :failure_min, :failure_max, :message
  
  def initialize(md)
    md.names.each do |key|
      if FLOAT_VALUES.include?(key.to_sym)
        send("#{key}=", md[key.to_sym].to_f)
      else
        send("#{key}=", md[key.to_sym])
      end
    end
    
    t = Time.at(self.time.to_i)
    self.time = Config::timezone.utc_to_local(t)
  end
end

module NotificationHandler
  
  REGEXP = %r{^\
Severity: (?<severity>[^\n]+)\n\
Time: (?<time>[0-9]+)\n\
(?:Host: (?<host>[^\n]+)\n)?\
(?:Plugin: (?<plugin>[^\n]+)\n)?\
(?:PluginInstance: (?<plugin_instance>[^\n]+)\n)?\
(?:Type: (?<type>[^\n]+)\n)?\
(?:TypeInstance: (?<type_instance>[^\n]+)\n)?\
(?:DataSource: (?<datasource>[^\n]+)\n)?\
(?:CurrentValue: (?<value>[^\n]+)\n)?\
(?:WarningMin: (?<warn_min>[^\n]+)\n)?\
(?:WarningMax: (?<warn_max>[^\n]+)\n)?\
(?:FailureMin: (?<failure_min>[^\n]+)\n)?\
(?:FailureMax: (?<failure_max>[^\n]+)\n)?\
\n+\
(?:(?<message>[^\n]+)\n)?$}
  
  def parse(str)
    m = REGEXP.match(str)
    m ? Notification.new(m) : nil
  end
  
  def receive_data(data)
    # puts "DATA: #{data}"
    if ev = parse(data)
      Config::logger.debug("[#{ev.time.strftime('%H:%m:%S')} - #{ev.host}] #{ev.severity} ")
      send_email("[$$$] #{ev.host} - #{ev.plugin}:#{ev.type}:#{ev.type_instance} - #{ev.severity}", %{\
        Current Value: #{ev.value}
        Warning thresholds: #{ev.warn_min} - #{ev.warn_max}
        Failure thresholds: #{ev.failure_min} - #{ev.failure_max}
        
        Message: #{ev.message}
      })
    end
  end
  
end

# EM::kqueue = true

EM::run do  
  EM::open_datagram_socket('127.0.0.1', 6000, NotificationHandler)
end


