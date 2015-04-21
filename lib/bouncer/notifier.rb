require 'slack-notifier'

module Bouncer
  class Notifier
    def initialize(slack_configs={})
      webhook_url = slack_configs['slack']['webhook_url']
      channel = "##{slack_configs['slack']['channel']}"
      username = slack_configs['slack']['username']
      @icon_url = slack_configs['slack']['icon_url']
      unless @icon_url
        @icon_emoji = ":#{slack_configs['slack']['icon_emoji']}:" || ":ghost:"
      end
      @notifier = Slack::Notifier.new(slack_configs['slack']['webhook_url'], channel: channel, username: username)
    end

    def post(message)
      if @icon_url
        @notifier.ping(message, icon_url: @icon_url)
      else
        @notifier.ping(message, icon_emoji: @icon_emoji)
      end
    end
  end
end