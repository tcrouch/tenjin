# frozen_string_literal: true

# Drops two users columns the app never reads or writes.
#
# Deploy only once every dyno runs code that ignores them: with partial
# inserts off, a dyno that still caches them names them in each INSERT.
class RemoveTypeAndPhotoFromUsers < ActiveRecord::Migration[7.2]
  def up
    execute "SET LOCAL lock_timeout TO '10s'"

    remove_column :users, :type
    remove_column :users, :photo
  end

  def down
    add_column :users, :photo, :string
    add_column :users, :type, :string
  end
end
