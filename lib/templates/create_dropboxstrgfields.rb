class CreateDropboxstrgfields < ActiveRecord::Migration
  def up
    add_column :cloudstrgusers, :dropbox_akey, :string 
    add_column :cloudstrgusers, :dropbox_asecret, :string 
  end

  def down
    remove_column :cloudstrgusers, :dropbox_akey
    remove_column :cloudstrgusers, :dropbox_asecret
  end
end