require 'sequel'

class Discodancer
  class Webhook < Sequel::Model
    many_to_many :websites

    def before_create
      self.created_at ||= Time.now
      super
    end

    def before_destroy
      DB[:webhooks_websites].where(webhook_id: self.id).delete
      super
    end
  end
end
