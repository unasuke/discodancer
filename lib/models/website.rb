require 'sequel'
require 'faraday'
require 'rss'

class Discodancer
  class Website < Sequel::Model
    many_to_many :webhooks

    def before_create
      self.created_at ||= Time.now
      self.last_checked_at ||= Time.now
      super
    end

    def before_destroy
      DB[:webhooks_websites].where(website_id: self.id).delete
      super
    end

    def need_retrieve?
      # TODO: iikanjini yaru
      true
    end

    def fetch_feed
      response = Faraday.get(self.url) do |request|
        request.headers['User-Agent'] = 'Discodancer https://github.com/unasuke/discodancer'
      end
      RSS::Parser.parse(response.body)
    end
  end
end
