class PagesController < ApplicationController
  def landing
    render 'landing'
    @facebook_posts = FacebookPost.recent.limit(5)
  end
end
