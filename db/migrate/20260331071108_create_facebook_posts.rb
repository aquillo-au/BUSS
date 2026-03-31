class CreateFacebookPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :facebook_posts do |t|
      t.string :facebook_post_id
      t.text :message
      t.string :image_url
      t.string :post_url
      t.datetime :published_at

      t.timestamps
    end
  end
end
