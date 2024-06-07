require 'sequel'
require 'logger'
require 'timers'

DB = Sequel.connect('sqlite://discodancer.db')

require_relative 'commands'
require_relative 'crawler'

class Discodancer
  def initialize
    @db = DB
    $stdout.sync = true
    @logger = Logger.new($stdout)
    @crawler = Crawler.new(db: @db, logger: @logger)
    @timers = Timers::Group.new
  end

  def run
    @timers.every(10) { @crawler.crawl }

    Signal.trap(:INT) do
      @timers.cancel
      exit
    end

    @logger.info 'Discodancer started'
    loop { @timers.wait }
  end
end

