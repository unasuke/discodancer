require_relative 'models'

class Discodancer
  class Crawler
    def initialize(db:, logger:)
      @db = db
      @logger = logger
    end

    def crawl
      @logger.info 'Crawling websites'
    end
  end
end
