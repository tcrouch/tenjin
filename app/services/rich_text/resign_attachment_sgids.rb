# frozen_string_literal: true

# Re-signs the signed global ids inside stored Action Text attachments.
#
# The SHA256 key derivation that load_defaults 7.0 and later select does not
# verify ids signed under SHA1, so every embedded image renders as a missing
# attachment (☒). Upgrading re-signs SHA1 ids with the current verifier;
# downgrading does the reverse, so a rolled-back release can resolve them.
#
# Rerunnable: ids already in the target form, and ids whose record is gone,
# are left alone. Ids that verify under neither key fail the run, so a wrong
# old_secret shows up instead of passing silently.
class RichText::ResignAttachmentSgids < ApplicationCommand
  PURPOSE = ActionText::Attachable::LOCATOR_NAME
  OUTCOMES = %i[resigned already_target missing unverifiable].freeze
  DIRECTIONS = %i[upgrade downgrade].freeze

  # Signs and verifies sgids as Rails 6.1 wrote them: a SHA1-derived key, a
  # Marshal payload, and a gid suffixed `?expires_in` for a non-expiring id.
  class Sha1Signer
    attr_reader :verifier

    def initialize(secret)
      key = ActiveSupport::KeyGenerator
        .new(secret, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1)
        .generate_key("signed_global_ids")
      @verifier = GlobalID::Verifier.new(key)
      @signer = GlobalID::Verifier.new(key, serializer: Marshal)
    end

    def call(record)
      @signer.generate({"gid" => "#{record.to_gid}?expires_in", "purpose" => PURPOSE, "expires_at" => nil})
    end
  end

  # old_secret keys the SHA1 side: the secret the Rails 6.1 release runs with
  def initialize(old_secret: Rails.application.secret_key_base, direction: :upgrade)
    unless DIRECTIONS.include?(direction)
      raise ArgumentError, "direction must be one of #{DIRECTIONS.join(", ")}, got #{direction.inspect}"
    end

    @direction = direction
    @sha1 = Sha1Signer.new(old_secret)
    @counts = OUTCOMES.index_with(0)
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
      outcome, sgid = resign(node["sgid"])
      @counts[outcome] += 1
      if sgid
        node["sgid"] = sgid
        changed = true
      end
      node
    end
    # Skips callbacks: before_save rebuilds the embeds from the attachables,
    # which a downgraded id cannot resolve, and purges the blobs it detaches.
    rich_text.update_column(:body, ActionText::Content.new(fragment).to_html) if changed
  end

  # [outcome, new_sgid_or_nil]
  def resign(sgid)
    return [:already_target, nil] if parse(sgid, target_verifier)

    source = parse(sgid, source_verifier)
    return [:unverifiable, nil] unless source

    [:resigned, sign(source.find)]
  rescue ActiveRecord::RecordNotFound
    [:missing, nil]
  end

  def parse(sgid, verifier)
    SignedGlobalID.parse(sgid, for: PURPOSE, verifier: verifier)
  end

  def upgrade? = @direction == :upgrade

  def target_verifier = upgrade? ? SignedGlobalID.verifier : @sha1.verifier

  def source_verifier = upgrade? ? @sha1.verifier : SignedGlobalID.verifier

  def sign(record) = upgrade? ? record.attachable_sgid : @sha1.call(record)
end
