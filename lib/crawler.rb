require 'faraday'
require 'rss'
require_relative 'models'

class Discodancer
  class Crawler
    def initialize(db:, logger:)
      @db = db
      @logger = logger
    end

    def crawl
      @logger.info 'Crawling websites'
      Website.eager(:webhooks).all.each do |website|
        next unless website.need_retrieve?

        last_updated_at = website.last_updated_at || Time.parse("2000-01-01 00:00:00")
        begin
          feed = website.fetch_feed
          feed.items.filter do |item|
            item.updated.content.localtime > website.last_updated_at
          end.sort_by do |entry|
            entry.updated.content.localtime
          end.each do |entry|
            last_updated_at = entry.updated.content.localtime if entry.updated.content.localtime >= last_updated_at
            website.webhooks.each do |webhook|
              @logger.info "Post entry to webhook id:#{webhook.id} #{webhook.workspace} ##{webhook.channel}"
              webhook.post!(website, entry)
            end
          end
          website.last_updated_at = last_updated_at
        rescue => e
          @logger.error "Error crawling website id:#{website.id} #{website.url}: #{e.class} #{e.message}"
        ensure
          website.last_checked_at = Time.now
          website.save
        end
      end
    end
  end
end
