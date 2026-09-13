# frozen_string_literal: true

# Re-signs the signed global ids inside stored Action Text attachments.
#
# Rails 7.0 derives the signed-global-id key with SHA256 instead of SHA1, so
# ids signed before the upgrade no longer verify and every embedded image
# renders as a missing attachment (☒). Upgrading verifies each tag with the
# old derivation, resolves it, and re-signs it with the current verifier.
# Downgrading does the reverse, writing the pre-Rails 7 token so a rolled
# back release can still resolve the attachments. Pass the secret the other
# release runs with as old_secret when SECRET_KEY_BASE differs between them.
#
# Rerunnable: ids already in the target form are skipped and ids whose record
# is gone are left alone. Ids that verify under neither key are left alone
# too and reported as a failure, so a wrong old_secret shows up instead of
# passing silently; rerun with the right one for the remainder.
class RichText::ResignAttachmentSgids < ApplicationCommand
  PURPOSE = ActionText::Attachable::LOCATOR_NAME
  OUTCOMES = %i[resigned current missing unverifiable].freeze
  DIRECTIONS = %i[upgrade downgrade].freeze

  # The verifier Rails built before 7.0 (a SHA1-derived key) and the token
  # globalid wrote with it: a self-validated Marshal hash, byte-identical to
  # what production stores, down to the `?expires_in` the old gem left on the
  # gid when Action Text asked for a non-expiring id.
  class LegacySigner
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

  def initialize(old_secret: Rails.application.secret_key_base, direction: :upgrade)
    unless DIRECTIONS.include?(direction)
      raise ArgumentError, "direction must be one of #{DIRECTIONS.join(", ")}, got #{direction.inspect}"
    end

    @direction = direction
    @legacy = LegacySigner.new(old_secret)
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
    # Written without callbacks: Action Text's before_save recomputes the
    # embeds from the attachables, which do not resolve under the current
    # verifier after a downgrade, and detaching them purges the blobs.
    rich_text.update_column(:body, ActionText::Content.new(fragment).to_html) if changed
  end

  # [outcome, new_sgid_or_nil]. :current means already in the target form.
  def resign(sgid)
    return [:current, nil] if parse(sgid, target_verifier)

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

  def target_verifier = upgrade? ? SignedGlobalID.verifier : @legacy.verifier

  def source_verifier = upgrade? ? @legacy.verifier : SignedGlobalID.verifier

  def sign(record) = upgrade? ? record.attachable_sgid : @legacy.call(record)
end
