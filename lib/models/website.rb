require 'sequel'

class Discodancer
  class Website < Sequel::Model
    many_to_many :webhooks

    def before_create
      self.created_at ||= Time.now
      super
    end

    def before_destroy
      DB[:webhooks_websites].where(website_id: self.id).delete
      super
    end
  end
end
