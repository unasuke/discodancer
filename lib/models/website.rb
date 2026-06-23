require 'sequel'
require 'faraday'
require 'rss'

class Discodancer
  class Website < Sequel::Model
    many_to_many :webhooks

    MIN_FETCH_INTERVAL = ENV.fetch('DISCODANCER_MIN_FETCH_INTERVAL_SECOND', 600).to_i
    MAX_FETCH_INTERVAL = ENV.fetch('DISCODANCER_MAX_FETCH_INTERVAL_SECOND', 86400).to_i
    FETCH_INTERVAL_STEP = ENV.fetch('DISCODANCER_FETCH_INTERVAL_STEP_SECOND', MIN_FETCH_INTERVAL).to_i

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
      next_fetch_at.nil? || Time.now >= next_fetch_at
    end

    def current_fetch_interval
      fetch_interval_seconds || MIN_FETCH_INTERVAL
    end

    def advance_fetch_interval(found_new:)
      interval = found_new ? MIN_FETCH_INTERVAL : [current_fetch_interval + FETCH_INTERVAL_STEP, MAX_FETCH_INTERVAL].min
      self.fetch_interval_seconds = interval
      self.next_fetch_at = Time.now + interval
    end

    def fetch_feed
      response = Faraday.get(self.url) do |request|
        request.headers['User-Agent'] = 'Discodancer https://github.com/unasuke/discodancer'
      end
      RSS::Parser.parse(response.body, false)
    end
  end
end
