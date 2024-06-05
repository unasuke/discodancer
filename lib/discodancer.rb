require 'sequel'
require 'logger'
require 'timers'

DB = Sequel.connect('sqlite://discodancer.db')

require_relative 'commands'
require_relative 'crawler'

class Discodancer
  def initialize
    @db = DB
    @logger = Logger.new($stdout)
    @crawler = Crawler.new(db: @db, logger: @logger)
    @timers = Timers::Group.new
  end

  def run
    @timers.every(10) { @crawler.crawl }
    loop { @timers.wait }
  end
end

