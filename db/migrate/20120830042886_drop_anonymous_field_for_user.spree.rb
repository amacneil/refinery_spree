# This migration comes from spree (originally 20101103212716)
class DropAnonymousFieldForUser < ActiveRecord::Migration
  def up
    unless defined?(User)
      remove_column :users, :anonymous
    end
  end

  def down
    add_column :users, :anonymous, :boolean
  end
end
