require 'reline'
require 'faraday'
require 'rss'
require 'tty-prompt'

class Discodancer
  class Commands
    def self.setup
      pp "hello"
    end

    def self.console
      prompt = TTY::Prompt.new
      loop do
        case prompt.select("Which operations do you want?", ["website", "webhook", "outgoing setting", "exit"])
        when "website"
          self.website_console
        when "webhook"
          self.webhook_console
        when "outgoing setting"
          self.outgoing_setting_console
        when "exit"
          break
        else
          prompt.error("Invalid operation")
        end
      end
    end

    def self.webhook_console
      prompt = TTY::Prompt.new
      loop do
        case prompt.select("Which webhook operation do you want?", ["list webhook", "add webhook", "delete webhook", "exit"])
        when "list webhook"
          self.list_webhook_console
        when "add webhook"
          self.add_webhook_console
        when "delete webhook"
          self.delete_webhook_console
        when "exit"
          break
        else
          prompt.error("Invalid operation")
        end
      end
    end

    def self.list_webhook_console
      prompt = TTY::Prompt.new
      webhooks = Webhook.eager(:websites).all
      if webhooks.empty?
        prompt.warn("No webhooks registered")
        return
      end
      webhooks.each do |webhook|
        prompt.say <<~WEBHOOK
          id: #{webhook.id}  #{webhook.workspace} ##{webhook.channel}
            provider     : #{webhook.provider}
            url          : #{webhook.url}
            linked sites : #{webhook.websites.size}
        WEBHOOK
      end
      prompt.keypress("Press any key to continue")
    end

    def self.add_webhook_console
      prompt = TTY::Prompt.new
      loop do
        webhook = Webhook.new
        url = prompt.ask("Enter the webhook url (If you want to exit, type 'exit')")
        break if url == 'exit'
        webhook.url = url
        webhook.workspace = prompt.ask("Enter the workspace name for identify the webhook")
        webhook.channel = prompt.ask("Enter the channel name for identify the webhook")
        webhook.provider = 'discord' # TODO: Add provider selection
        prompt.say <<~WEBHOOK
          Webhook URL : #{webhook.url}
          Workspace : #{webhook.workspace}
          Channel : #{webhook.channel}
        WEBHOOK
        if prompt.yes?("Save this webhook?")
          webhook.save
          prompt.ok("Webhook saved successfully => id: #{webhook.id}, workspace: #{webhook.workspace}, channel: #{webhook.channel}\n")
        end
      end
    end

    def self.delete_webhook_console
      prompt = TTY::Prompt.new
      loop do
        webhook_choices = {"exit" => 0}
        Webhook.all.each do |webhook|
          webhook_choices["id: #{webhook.id} #{webhook.workspace} ##{webhook.channel}"] = webhook.id
        end

        begin
          choosen_webhook_id = prompt.select("Select the webhook to delete (If you want to exit, select 'exit')", webhook_choices)
          break if choosen_webhook_id == 0
          webhook = Webhook[choosen_webhook_id]
          prompt.say <<~WEBHOOK
            Webhook URL : #{webhook.url}
            Workspace : #{webhook.workspace}
            Channel : #{webhook.channel}
          WEBHOOK
          if prompt.yes?("Delete this webhook?")
            webhook.destroy
            prompt.ok("Webhook deleted successfully => id: #{webhook.id}, workspace: #{webhook.workspace}, channel: #{webhook.channel}\n")
          end
        rescue => e
          prompt.error "Exception: #{e.message}"
        end
      end
    end

    def self.outgoing_setting_console
      prompt = TTY::Prompt.new
      loop do
        case prompt.select("Which outgoing setting operation do you want?", ["set outgoing setting", "list outgoing setting", "exit"])
        when "set outgoing setting"
          self.set_outgoing_setting_console
        when "list outgoing setting"
          self.list_outgoing_setting_console
        when "exit"
          break
        else
          prompt.error("Invalid operation")
        end
      end
    end

    def self.set_outgoing_setting_console
      prompt = TTY::Prompt.new
      loop do
        # Update each loop
        websites = Website.eager(:webhooks).all
        website_choices = {"exit" => 0}
        websites.each do |website|
          website_choices["id: #{website.id} #{website.name} (#{website.webhooks.size} outgoig webhooks)"] = website.id
        end
        webhooks = Webhook.all
        webhook_choices = {"exit" => 0}
        webhooks.each do |webhook|
          webhook_choices["id: #{webhook.id} #{webhook.workspace} ##{webhook.channel}"] = webhook.id
        end

        begin
          choosen_website_id = prompt.select("Select the website to set outgoing webhook (If you want to exit, select 'exit')", website_choices)
          break if choosen_website_id == 0
          choosen_webhook_id = prompt.select("Select the webhook to set outgoing", webhook_choices)
          break if choosen_webhook_id == 0
          choosen_website = Website[choosen_website_id]
          choosen_webhook = Webhook[choosen_webhook_id]
          prompt.say(
            "New outgoing setting: id:#{choosen_website.id} #{choosen_website.name} => id:#{choosen_webhook.id} #{choosen_webhook.workspace} ##{choosen_webhook.channel}"
          )
          if prompt.yes?("Save this setting?")
            choosen_website.add_webhook(choosen_webhook)
            prompt.ok("Outgoing setting saved successfully\n")
          end
        rescue => e
          prompt.error "Exception: #{e.message}"
        end
      end
    end

    def self.list_outgoing_setting_console
      prompt = TTY::Prompt.new
      websites = Website.eager(:webhooks).all
      if websites.empty?
        prompt.warn("No websites registered")
        return
      end
      websites.each do |website|
        if website.webhooks.empty?
          prompt.say "id: #{website.id} #{website.name} => (no outgoing webhooks)"
        else
          hooks = website.webhooks.map { |w| "id:#{w.id} #{w.workspace} ##{w.channel}" }.join(", ")
          prompt.say "id: #{website.id} #{website.name} => #{hooks}"
        end
      end
      prompt.keypress("Press any key to continue")
    end

    def self.website_console
      prompt = TTY::Prompt.new
      loop do
        case prompt.select("Which website operation do you want?", ["list website", "add website", "delete website", "exit"])
        when "list website"
          self.list_website_console
        when "add website"
          self.add_website_console
        when "delete website"
          self.delete_website_console
        when "exit"
          break
        else
          prompt.error("Invalid operation")
        end
      end
    end

    def self.list_website_console
      prompt = TTY::Prompt.new
      websites = Website.eager(:webhooks).all
      if websites.empty?
        prompt.warn("No websites registered")
        return
      end
      websites.each do |website|
        prompt.say <<~WEBSITE
          id: #{website.id}  #{website.name}
            feed url        : #{website.url}
            outgoing hooks  : #{website.webhooks.size}
            last updated at : #{website.last_updated_at || '-'}
            last checked at : #{website.last_checked_at || '-'}
            next fetch at   : #{website.next_fetch_at || '-'}
            fetch interval  : #{website.current_fetch_interval}s
        WEBSITE
      end
      prompt.keypress("Press any key to continue")
    end

    def self.add_website_console
      prompt = TTY::Prompt.new
      loop do
        begin
          url = prompt.ask("Enter the feed url (If you want to exit, type 'exit')")
          break if url == 'exit'
          response = Faraday.get(url)
          feed =  RSS::Parser.parse(response.body)
          website = Website.new(name: "#{feed.title.content}", url: url)
          prompt.say <<~EOF
          Website name : #{website.name}
          Feed URL : #{website.url}
          EOF
          if prompt.yes?("Save this website?")
            website.save
            prompt.ok("Website saved successfully => id: #{website.id}, name: #{website.name}, feed url: #{website.url}\n")
          end
        rescue => e
          prompt.error "Exception: #{e.message}"
        end
      end
    end

    def self.delete_website_console
      prompt = TTY::Prompt.new
      loop do
        website_choices = {"exit" => 0}
        Website.all.each do |website|
          website_choices["id: #{website.id} #{website.name}"] = website.id
        end

        begin
          choosen_website_id = prompt.select("Select the website to delete (If you want to exit, select 'exit')", website_choices)
          break if choosen_website_id == 0
          website = Website[choosen_website_id]
          prompt.say <<~EOF
          Website name : #{website.name}
          Feed URL : #{website.url}
          EOF
          if prompt.yes?("Delete this website?")
            website.destroy
            prompt.ok("Website deleted successfully => id: #{website.id}, name: #{website.name}, feed url: #{website.url}\n")
          end
        rescue => e
          prompt.error "Exception: #{e.message}"
        end
      end
    end
  end
end

