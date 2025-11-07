class CreateShortUrls < ActiveRecord::Migration[8.0]
  def change
    create_table :short_urls do |t|
      t.text :original_url
      t.string :code

      t.timestamps
    end
    add_index :short_urls, :code
  end
end
