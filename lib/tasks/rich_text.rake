# frozen_string_literal: true

namespace :rich_text do
  resign = lambda do |direction|
    old_secret = ENV["OLD_SECRET_KEY_BASE"].presence || Rails.application.secret_key_base
    result = RichText::ResignAttachmentSgids.call(old_secret: old_secret, direction: direction)
    counts = result.payload
    already = (direction == :upgrade) ? "current" : "legacy"
    puts "re-signed #{counts[:resigned]}, already #{already} #{counts[:current]}, " \
      "record missing #{counts[:missing]}, unverifiable #{counts[:unverifiable]}"

    case result
    in {success: false}
      abort "#{counts[:unverifiable]} sgids verify under neither key; " \
        "set OLD_SECRET_KEY_BASE to the secret the other release runs with and rerun"
    in {success: true}
      nil
    end
  end

  desc "Re-sign Action Text attachment sgids after the Rails 7 key change; set OLD_SECRET_KEY_BASE if the secret was rotated"
  task(resign_attachment_sgids: :environment) { resign.call(:upgrade) }

  desc "Sign Action Text attachment sgids the pre-Rails 7 way before a rollback; set OLD_SECRET_KEY_BASE to the secret the old release runs with"
  task(downgrade_attachment_sgids: :environment) { resign.call(:downgrade) }
end
