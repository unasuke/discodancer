require 'logger'

desc 'Setup discodancer'
task :setup do
  require_relative 'lib/discodancer'
  Discodancer::Commands.setup
end

# https://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html#label-Running+migrations+from+a+Rake+task
desc "Migrate database"
task :migrate, [:version] do |t, args|
  require 'sequel/core'
  Sequel.extension :migration
  version = args[:version].to_i if args[:version]
  Sequel.connect('sqlite://discodancer.db', logger: Logger.new($stderr)) do |db|
    Sequel::Migrator.run(db, 'lib/migrations', target: version)
  end
end

task :console do
  require_relative 'lib/discodancer'
  Discodancer::Commands.console
end
