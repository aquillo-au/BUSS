require "net/http"
require "json"
require "uri"

class FacebookPostsService
  def self.fetch_and_save_posts
    page_id = ENV["FACEBOOK_PAGE_ID"]
    access_token = ENV["FACEBOOK_PAGE_ACCESS_TOKEN"]

    return false if page_id.blank? || access_token.blank?

    url = "https://graph.facebook.com/v18.0/#{page_id}/feed"
    uri = URI(url)
    uri.query = URI.encode_www_form({
      access_token: access_token,
      fields: "id,message,created_time,picture,link,story",
      limit: 10
    })

    begin
      response = Net::HTTP.get_response(uri)
      data = JSON.parse(response.body)

      return false if data["error"]

      posts = data["data"] || []
      count = 0

      posts.each do |post|
        next if FacebookPost.exists?(facebook_post_id: post["id"])
        next if post["message"].blank? && post["story"].blank?

        FacebookPost.create!(
          facebook_post_id: post["id"],
          message: post["message"] || post["story"],
          image_url: post["picture"],
          post_url: post["link"],
          published_at: post["created_time"]
        )
        count += 1
      end

      puts "✓ Saved #{count} new Facebook posts"
      true
    rescue => e
      puts "✗ Error fetching Facebook posts: #{e.message}"
      false
    end
  end
end
