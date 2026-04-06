class PagesController < ApplicationController
  def landing
    render "landing"
    @facebook_posts = FacebookPost.recent.limit(5).to_a
  end
end
