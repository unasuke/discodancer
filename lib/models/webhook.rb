require 'sequel'
require 'json'
require 'sanitize'
require 'uri'

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

    def post!(website, entry)
      case self.provider
      when "discord"
        post_to_discord(website, entry)
      else
        raise "Unknown provider #{self.provider}"
      end
    end

    private def post_to_discord(website, entry)
      Faraday.post(self.url) do |request|
        request.headers['Content-Type'] = 'application/json'
        request.body = discord_webhook_body(website, entry)
      end
    end

    private def discord_webhook_body(website, entry)
      entry_url = URI.parse(entry.link.href).tap do |uri|
        website_uri = URI.parse(website.url)
        uri.host = website_uri.host unless uri.host
        uri.scheme = website_uri.scheme unless uri.scheme
      end.to_s
      summary = Sanitize.fragment((entry&.summary&.content || entry&.content&.content || "")).gsub("\n", '').strip
      summary = "\r" + summary unless summary.empty?
      summary = summary[0..150] + "..." if summary.length > 150
      description = Sanitize.fragment(entry.title.content) + summary + "\r<#{entry_url}>"
      JSON.dump({
        embeds: [
          {
            title: website.name,
            description: description,
            timestamp: entry.updated.content.iso8601,
          }
        ],
      })
    end
  end
end
