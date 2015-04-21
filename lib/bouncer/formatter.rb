module Bouncer
  class Formatter
    class << self
      def mask_email(email)
        account, domain = email.split('@')
        "xxxxx@#{domain}"
      end
    end
  end
end