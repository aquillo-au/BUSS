namespace :facebook do
  desc "Fetch latest posts from Facebook page"
  task fetch_posts: :environment do
    if FacebookPostsService.fetch_and_save_posts
      puts "Facebook posts updated successfully!"
    else
      puts "Failed to update Facebook posts"
    end
  end
end
