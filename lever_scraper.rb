require 'httparty'
require 'nokogiri'
require 'json'
require 'date'

class Scraper

  def initialize(url)
    @url = url
  end

  def get_html
    HTTParty.get(@url).body
  end

  def get_json
    JSON.parse(get_html)
  end

  def lever_postings
    cleaned_postings = []
    document = Nokogiri::HTML(get_html)
    postings = document.css(".posting")
    postings.each do |posting|
      # Doing the & sign before the method is a "safe" method call in case the part before it is nil (in which case it would just return nil)
      title = posting.css("h5")&.first&.content
      location = posting.css(".sort-by-location")&.first&.content
      category = posting.css(".sort-by-team")&.first&.content
      link = posting.css(".posting-title")&.first&.attribute("href").content
      if title && location && link
        # might also want to add in an attribute for date and use Ruby Date.today to capture when the posting was scraped.
        cleaned_postings += [{title: title, location: location, category: category, link: link}]
      end
    end
    cleaned_postings
  end

  def export_to_csv(postings)
    date = Date.today
    CSV.open("#{date}_test_lever_postings.csv", "w") do |csv|
      csv << postings.first.keys # header row
      postings.each do |posting|
        csv << posting.values
      end
    end
  end

end

lever_scraper = Scraper.new("#{company_url}")
lever_postings = lever_scraper.lever_postings
lever_scraper.export_to_csv(lever_postings)
# Now you should see the file lever_postings.csv in the same directory as this Ruby file.
