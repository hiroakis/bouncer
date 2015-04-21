require 'optparse'
require 'yaml'

module Bouncer
  class Base
    def initialize
      @options = {
        config_file: File.join(File.dirname(__FILE__), '../../.config.yml'),
        daemonized: false,
        pid: "/var/run/bouncer.pid"
      }
      optparse = OptionParser.new
      optparse.on("-c [CONFIG_FILE]", "--config [CONFIG_FILE]", "config file") do |file|
        @options[:config_file] = File.join(file)
      end
      optparse.on("-d", "--daemonize", "enable daemonize") do |daemon|
        @options[:daemonized] = daemon
      end
      optparse.on("-p [PID_FILE]", "--pid [PID_FILE]", "pid file") do |pid_file|
        @options[:pid] = pid_file
      end
      optparse.parse!
    end

    def run(args={})
      setup
      sqs = Bouncer::SQS.new(@configs)
      slack = Bouncer::Notifier.new(@configs)

      while true
        sqs.dequeue
        masked_dest_addrs = sqs.destination_addresses.map do |addr|
          Bouncer::Formatter.mask_email(addr)
        end
        post_data = "
          bounced_time: #{sqs.bounced_time}
          send_time: #{sqs.send_time}
          source_address: #{sqs.source_address}
          destination_address: #{masked_dest_addrs}
        "
        slack.post(post_data.to_s)
      end
    end

    def setup
      if @options[:daemonized]
        unless daemonize
          exit 1
        end
      end
      signal
      load_configs
    end

    def load_configs
      if File.exist? @options[:config_file]
        @configs = YAML.load_file(@options[:config_file])
      else
        puts "config file not found"
        exit 1
      end
    end

    private
    def signal
      Signal.trap(:INT) { exit }
      Signal.trap(:TERM) { exit }
    end

    private
    def daemonize
      begin
        Process.daemon(true, true)
        File.open(@options[:pid], 'w') do |pid_file|
          pid_file.puts(Process.pid)
        end
        true
      rescue Exception => e
        p e
        false
      end
    end
  end
end