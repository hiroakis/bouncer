require 'aws-sdk'

module Bouncer
  class SQS
    def initialize(aws_configs={})
      Aws.config[:access_key_id] = aws_configs["aws"]["access_key_id"]
      Aws.config[:secret_access_key] = aws_configs["aws"]["secret_access_key"]
      Aws.config[:region] = aws_configs["aws"]["region"]
      account_id = aws_configs["aws"]["account_id"]
      queue = aws_configs["aws"]["sqs"]["queue"]
      @queue_url = "https://sqs.#{Aws.config[:region]}.amazonaws.com/#{account_id}/#{queue}"
      @sqs = Aws::SQS::Client.new
    end

    attr_reader :bounced_time, :bounced_recipients, :send_time, :source_address, :destination_addresses

    def dequeue
      receive_messages.each do |msg|
        remove(msg)
      end
    end

    def receive_messages
      @sqs.receive_message(:queue_url => @queue_url, :wait_time_seconds => 10)[:messages].each do |msg|
        @bounced_time = JSON.parse(msg.body)["Timestamp"]
        # @notification_type = JSON.parse(JSON.parse(msg.body)["Message"])["bounce"]["bouncedType"]
        # @reporting_mta = JSON.parse(JSON.parse(msg.body)["Message"])["bounce"]["reportintMTA"]
        @bounced_recipients = JSON.parse(JSON.parse(msg.body)["Message"])["bounce"]["bouncedRecipients"]
        # @feedback_id = JSON.parse(JSON.parse(msg.body)["Message"])["bounce"]["feedbackId"]
        @send_time = JSON.parse(JSON.parse(msg.body)["Message"])["mail"]["timestamp"]
        @source_address = JSON.parse(JSON.parse(msg.body)["Message"])["mail"]["source"]
        @destination_addresses = JSON.parse(JSON.parse(msg.body)["Message"])["mail"]["destination"]
      end
    end

    def remove(message)
      @sqs.delete_message(:queue_url => @queue_url, :receipt_handle => message[:receipt_handle])
    end
  end
end
