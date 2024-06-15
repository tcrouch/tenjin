# frozen_string_literal: true

require 'rails_helper'

YOUTUBE_VALID = [
  %w[www.youtube.com/@OneVoiceChildrensChoir?v=FUQheX3PSnY FUQheX3PSnY],
  %w[www.youtube.com/@Starlight.Lyrics?v=Sr3X0DCXI-M Sr3X0DCXI-M],
  %w[www.youtube.com/@dadimakesmusic?v=VFZNvj-HfBU VFZNvj-HfBU],
  %w[m.youtube.com/watch?v=VFZNvj-HfBU VFZNvj-HfBU],
  %w[www.youtube-nocookie.com/embed/VFZNvj-HfBU VFZNvj-HfBU],
  %w[www.youtube-nocookie.com/embed/VFZNvj-HfBU?autoplay=1 VFZNvj-HfBU],
  %w[www.youtube.com/embed/VFZNvj-HfBU VFZNvj-HfBU],
  %w[www.youtube.com/embed/VFZNvj-HfBU?autoplay=1 VFZNvj-HfBU],
  %w[www.youtube.com/v/VFZNvj-HfBU?fs=1&hl=en_US VFZNvj-HfBU],
  %w[www.youtube.com/watch?v=VFZNvj-HfBU VFZNvj-HfBU],
  %w[youtu.be/VFZNvj-HfBU VFZNvj-HfBU],
  %w[youtu.be/VFZNvj-HfBU?t=120 VFZNvj-HfBU],
  %w[youtube-nocookie.com/embed/VFZNvj-HfBU VFZNvj-HfBU],
  %w[youtube.com/embed/VFZNvj-HfBU VFZNvj-HfBU],
  %w[youtube.com/v/VFZNvj-HfBU?fs=1&hl=en_US VFZNvj-HfBU],
  %w[youtube.com/watch?v=VFZNvj-HfBU VFZNvj-HfBU]
].freeze

VIMEO_VALID = [
  %w[player.vimeo.com/122054187 122054187],
  %w[vimeo.com/122054187 122054187],
  %w[www.vimeo.com/122054187 122054187]
].freeze

SCHEMES = ['', '//', 'http://', 'https://']

def prepend_schemes(links, schemes: SCHEMES)
  schemes.product(links).lazy.map { |scheme, (link, result)| ["#{scheme}#{link}", result] }
end

RSpec.describe Lesson do
  it { is_expected.to have_many(:questions) }
  it { is_expected.to belong_to(:topic) }

  describe 'validations' do
    let(:lesson) { build(:lesson) }

    it { is_expected.to validate_length_of(:title).is_at_least(3) }

    describe 'video links' do
      it 'accepts a valid YouTube link', :aggregate_failures do
        prepend_schemes(YOUTUBE_VALID).each do |url, _|
          lesson.video_link = url
          expect(lesson).to be_valid
        end
      end

      it 'accepts a valid vimeo link', :aggregate_failures do
        prepend_schemes(VIMEO_VALID).each do |url, _|
          lesson.video_link = url
          expect(lesson).to be_valid
        end
      end

      it 'rejects other links' do
        lesson.video_link = "badtu.be/VFZNvj-HfBU"
        expect(lesson).not_to be_valid
      end
    end
  end

  describe '#video_link=' do
    context 'with a matching YouTube URL' do
      let(:lesson) { Lesson.new }
      let(:link) { YOUTUBE_VALID[0][0] }
      let(:vid) { YOUTUBE_VALID[0][1] }

      it 'sets video_id' do
        expect { lesson.video_link = link }.to change(lesson, :video_id).to(vid)
      end

      it 'sets category to "youtube"' do
        expect { lesson.video_link = link }.to change(lesson, :category).to('youtube')
      end
    end

    context 'with a matching vimeo URL' do
      let(:lesson) { Lesson.new }
      let(:link) { VIMEO_VALID[0][0] }
      let(:vid) { VIMEO_VALID[0][1] }

      it 'defines video_id' do
        expect { lesson.video_link = link }.to change(lesson, :video_id).to(vid)
      end

      it 'defines category' do
        expect { lesson.video_link = link }.to change(lesson, :category).to('vimeo')
      end
    end
  end
end
