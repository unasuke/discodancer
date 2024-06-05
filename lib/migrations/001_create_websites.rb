require 'sequel'

Sequel.migration do
  up do
    create_table(:websites) do
      primary_key :id
      column :name, :string, null: false
      column :url, :string, null: false
      column :created_at, :datetime, null: false
      column :last_updated_at, :datetime
      column :last_checked_at, :datetime
    end
  end

  down { drop_table(:websites) }
end
