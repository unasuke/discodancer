
require 'sequel'

Sequel.migration do
  up do
    create_table(:webhooks) do
      primary_key :id
      column :workspace, :string, null: false
      column :channel, :string, null: false
      column :provider, :string, null: false
      column :url, :string, null: false
      column :created_at, :datetime, null: false
    end

    create_join_table(website_id: :websites, webhook_id: :webhooks)
  end

  down do
    drop_table(:webhooks, :webhooks_websites)
  end
end
