require 'httparty'
require 'nokogiri'
require 'json'
require 'date'

class Scraper
  attr_accessor :url

  def get_html
    response = HTTParty.get(@url)
    if response.code.to_s != "200"
      return false
    end
    response.body
  end

  def document
    Nokogiri::HTML(get_html)
  end

  def self.export_to_csv(postings)
    date = Date.today
    CSV.open("#{date}_master_postings.csv", "w") do |csv|
      # Need to find some kind of way to replace this ("test") with the name of the company. Running into a scoping issue.
      csv << postings.first.keys # header row
      postings.each do |posting|
        csv << posting.values
      end
    end
  end
end

class Lever < Scraper

  def initialize(company)
    @url = "https://jobs.lever.co/#{company[:slug]}"
    @company = company
  end

  def postings
    cleaned_postings = []
    postings = document.css(".posting")
    postings.each do |posting|
      # Doing the & sign before the method is a "safe" method call in case the part before it is nil (in which case it would just return nil)
      title = posting.css("h5")&.first&.content
      location = posting.css(".sort-by-location")&.first&.content
      category = posting.css(".sort-by-team")&.first&.content
      link = posting.css(".posting-title")&.first&.attribute("href").content
      if title && location && link
        # might also want to add in an attribute for date and use Ruby Date.today to capture when the posting was scraped.
        cleaned_postings += [{company: @company[:name], title: title, location: location, category: category, link: link}]
      end
    end
    cleaned_postings
  end
end


# class AngelList < Scraper
#
#   def initialize(company)
#     @url = "https://angel.co/#{company[:slug]}"
#     @company = company
#   end
#
#   def postings
#     cleaned_postings = []
#     postings = document.css(".posting")
#     postings.each do |posting|
#       # Doing the & sign before the method is a "safe" method call in case the part before it is nil (in which case it would just return nil)
#       title = posting.css("h5")&.first&.content
#       location = posting.css(".sort-by-location")&.first&.content
#       category = posting.css(".sort-by-team")&.first&.content
#       link = posting.css(".posting-title")&.first&.attribute("href").content
#       if title && location && link
#         # might also want to add in an attribute for date and use Ruby Date.today to capture when the posting was scraped.
#         cleaned_postings += [{company: @company[:name], title: title, location: location, category: category, link: link}]
#       end
#     end
#     cleaned_postings
#   end

class Greenhouse < Scraper

    def initialize(company)
      @base_url = "https://boards.greenhouse.io"
      @url = @base_url + "/#{company[:slug]}"
      @company = company
    end

    def postings
      cleaned_postings = []
      postings = document.css(".opening")
      postings.each do |posting|
        # Doing the & sign before the method is a "safe" method call in case the part before it is nil (in which case it would just return nil)
        title = posting.css("a")&.first&.content
        location = posting.css(".location")&.first&.content
        category = "n/a"
        link = @base_url + posting.css("a")&.first&.attribute("href").content
        if title && location && link
          # might also want to add in an attribute for date and use Ruby Date.today to capture when the posting was scraped.
          cleaned_postings += [{company: @company[:name], title: title, location: location, category: category, link: link}]
        end
      end
      cleaned_postings
    end

end

# This is only useful if you want to guess the scrapers
# SCRAPERS = [Lever, AngelList]
# def get_scraper(company)
#   SCRAPERS.each do |scraper|
#     temp_scraper = scraper.new(company)
#     html = temp_scraper.get_html
#     puts html
#     if html
#       return scraper
#     end
#   end
#   nil
# end

# This may not work because of syntax but general idea instead of defining companies here.
# CSV.read("companies.csv") do |row|
#   companies += [{ slug: row[0], name: row[1], scraper: row[2].constantize }]
# end

# Temporarily define companies here.
companies = [
  { slug: "useloom", name: "Loom", scraper: Lever },
  { slug: "deepgram", name: "Deepgram", scraper: Lever },
  { slug: "fountain", name: "Fountain", scraper: Lever },
  { slug: "ntopology", name: "nTopology", scraper: Lever },
  { slug: "lambda", name: "Lambda", scraper: Greenhouse },
]

all_postings = []
companies.each do |company|
  # use get_scraper if you want to guess
  # scraper = get_scraper(company)
  # next if scraper.nil?
  # otherwise use this:
  scraper = company[:scraper]
  new_scraper = scraper.new(company)
  updated_postings = new_scraper.postings
  all_postings += updated_postings
end

Scraper.export_to_csv(all_postings)
