# frozen_string_literal: true

# Re-signs the signed global ids inside stored Action Text attachments and
# points their editor previews at this release.
#
# The SHA256 key derivation that load_defaults 7.0 and later select does not
# verify ids signed under SHA1, so every embedded image renders as a missing
# attachment (☒). Upgrading re-signs SHA1 ids with the current verifier;
# downgrading does the reverse, so a rolled-back release can resolve them.
#
# Trix shows an attachment's image from the url attribute stored beside the
# sgid, which Rails never regenerates, so each attachment that resolves to a
# blob also gets the blob path the target release can serve, whether its
# stored url is signed by the other release or absent.
#
# Rerunnable: ids and urls already in the target form, and ids whose record
# is gone, are left alone. Ids that verify under neither key fail the run, so
# a wrong old_secret shows up instead of passing silently.
class RichText::ResignAttachmentSgids < ApplicationCommand
  PURPOSE = ActionText::Attachable::LOCATOR_NAME
  OUTCOMES = %i[resigned already_target missing unverifiable].freeze
  COUNTS = (OUTCOMES + %i[urls_rewritten]).freeze
  DIRECTIONS = %i[upgrade downgrade].freeze

  # Signs and verifies as Rails 6.1 did, from SHA1-derived keys: an sgid as a
  # Marshal payload whose gid is suffixed `?expires_in` for a non-expiring id,
  # and a blob id as a JSON envelope around a base64 Marshal message.
  class Sha1Signer
    attr_reader :verifier

    def initialize(secret)
      generator = ActiveSupport::KeyGenerator.new(secret, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1)
      key = generator.generate_key("signed_global_ids")
      @verifier = GlobalID::Verifier.new(key)
      @signer = GlobalID::Verifier.new(key, serializer: Marshal)
      @blob_signer = ActiveSupport::MessageVerifier.new(generator.generate_key("ActiveStorage"), serializer: :json)
    end

    def call(record)
      @signer.generate({"gid" => "#{record.to_gid}?expires_in", "purpose" => PURPOSE, "expires_at" => nil})
    end

    def blob_signed_id(blob)
      message = Base64.strict_encode64(Marshal.dump(blob.id))
      @blob_signer.generate({"_rails" => {"message" => message, "exp" => nil, "pur" => "blob_id"}})
    end
  end

  # old_secret keys the SHA1 side: the secret the Rails 6.1 release runs with
  def initialize(old_secret: Rails.application.secret_key_base, direction: :upgrade)
    unless DIRECTIONS.include?(direction)
      raise ArgumentError, "direction must be one of #{DIRECTIONS.join(", ")}, got #{direction.inspect}"
    end

    @direction = direction
    @sha1 = Sha1Signer.new(old_secret)
    @counts = COUNTS.index_with(0)
  end

  def call
    ActionText::RichText.where("body LIKE ?", "%sgid=%").find_each do |rich_text|
      # Reloaded under lock: the batch copy may be stale by the time its row is reached
      rich_text.with_lock { resign_attachments(rich_text) }
    end

    return failure(:unverifiable_sgids, payload: @counts) if @counts[:unverifiable].positive?

    success(@counts)
  end

  private

  def resign_attachments(rich_text)
    changed = false
    fragment = rich_text.body.fragment.replace(ActionText::Attachment.tag_name) do |node|
      next node if node["sgid"].blank? # a remote image, located by url
      outcome, record = locate(node["sgid"])
      @counts[outcome] += 1
      if outcome == :resigned
        node["sgid"] = sign(record)
        changed = true
      end
      if record.is_a?(ActiveStorage::Blob) && node["url"] != (path = blob_path(record))
        node["url"] = path
        @counts[:urls_rewritten] += 1
        changed = true
      end
      node
    end
    # Skips callbacks: before_save rebuilds the embeds from the attachables,
    # which a downgraded id cannot resolve, and purges the blobs it detaches.
    rich_text.update_column(:body, ActionText::Content.new(fragment).to_html) if changed
  end

  # [outcome, record or nil]
  def locate(sgid)
    if (target = parse(sgid, target_verifier))
      [:already_target, target.find]
    elsif (source = parse(sgid, source_verifier))
      [:resigned, source.find]
    else
      [:unverifiable, nil]
    end
  rescue ActiveRecord::RecordNotFound
    [:missing, nil]
  end

  def parse(sgid, verifier)
    SignedGlobalID.parse(sgid, for: PURPOSE, verifier: verifier)
  end

  # The same redirect route Trix is handed for a fresh upload, host stripped
  def blob_path(blob)
    signed_id = upgrade? ? blob.signed_id : @sha1.blob_signed_id(blob)
    Rails.application.routes.url_helpers.rails_service_blob_path(signed_id, blob.filename)
  end

  def upgrade? = @direction == :upgrade

  def target_verifier = upgrade? ? SignedGlobalID.verifier : @sha1.verifier

  def source_verifier = upgrade? ? @sha1.verifier : SignedGlobalID.verifier

  def sign(record) = upgrade? ? record.attachable_sgid : @sha1.call(record)
end
