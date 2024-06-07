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

        last_updated_at = Time.parse("2000-01-01 00:00:00")
        begin
          feed = website.fetch_feed
          feed.items.filter do |item|
            item.updated.content > website.last_checked_at
          end.sort_by do |entry|
            entry.updated.content
          end.each do |entry|
            last_updated_at = entry.updated.content if entry.updated.content > last_updated_at
            website.webhooks.each do |webhook|
              @logger.info "Post entry to webhook id:#{webhook.id} #{webhook.workspace} ##{webhook.channel}"
              webhook.post!(website, entry)
            end
          end
          website.last_checked_at = Time.now
          website.last_updated_at = last_updated_at
          website.save
        rescue => e
          @logger.error "Error crawling website id:#{website.id} #{website.url}: #{e.message}"
        end
      end
    end
  end
end
