require 'sequel'

Sequel.migration do
  up do
    alter_table(:websites) do
      add_column :fetch_interval_seconds, Integer
      add_column :next_fetch_at, DateTime
    end
  end

  down do
    alter_table(:websites) do
      drop_column :fetch_interval_seconds
      drop_column :next_fetch_at
    end
  end
end
