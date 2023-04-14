# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Question::ImportQuestions, default_creates: true do
  describe '#call' do
    context 'when importing questions' do
      let(:lesson_name) { FFaker::Lorem.words.join }
      let(:single_question) { build(:question_import_hash_with_lesson) }

      let(:single_lesson) { build_list(:question_import_hash_with_lesson, rand(1..10), lesson: lesson_name) }
      let(:multiple_lessons) { build_list(:question_import_hash_with_lesson, rand(1..10)) }
      let(:no_lessons) { build_list(:question_import_hash, rand(1..10)) }
      let(:topic_filename) { "#{topic.name}.json" }
      let(:multiple_lesson_service) { described_class.new(JSON.generate(multiple_lessons), topic, topic_filename) }

      it 'validates questions successfully' do
        result = multiple_lesson_service.call
        expect(result.success?).to eq(true)
      end

      it 'imports boolean questions' do
        result = described_class.new(JSON.generate([build(:question_import_hash_boolean)]), topic, topic_filename).call
        expect(result.success?).to eq(true)
      end

      it 'reports number of questions added' do
        result = multiple_lesson_service.call
        expect(result.number_questions_imported).to eq(multiple_lessons.length)
      end

      it 'saves questions to the database' do
        expect { multiple_lesson_service.call }.to change(Question, :count).by multiple_lessons.length
      end

      it 'saves answers to the database' do
        expect { multiple_lesson_service.call }.to change(Answer, :count).by(multiple_lessons.length * 4)
      end

      it 'fails validation for missing question type' do
        multiple_lessons[0] = multiple_lessons[0].except('question_type')
        result = multiple_lesson_service.call
        expect(result.success?).to eq(false)
      end

      it 'fails validation for missing question text body' do
        multiple_lessons[0]['question_text'] = ''
        result = multiple_lesson_service.call
        expect(result.success?).to eq(false)
      end

      it 'assigns the correct lesson name' do
        multiple_lesson_service.call
        expect(Lesson.first.title).to eq(multiple_lessons[0]['lesson'])
      end

      it 'assigns questions to existing lessons' do
        create(:lesson, title: single_lesson[0]['lesson'], topic: topic, category: :no_content, video_id: '')
        service = described_class.new(JSON.generate(single_lesson), topic, topic_filename)
        expect { service.call }.not_to change(Lesson, :count)
      end

      it 'creates multiple lessons' do
        expect { multiple_lesson_service.call }.to change(Lesson, :count).by multiple_lessons.length
      end

      it 'creates questions with existing lessons' do
        create(:lesson, title: single_lesson[0]['lesson'], topic: topic, category: :no_content, video_id: '')
        service = described_class.new(JSON.generate(single_lesson), topic, topic_filename)

        expect { service.call }.to change(Question, :count).by(single_lesson.length)
      end

      it 'adds questions with no lesson information' do
        result = described_class.new(JSON.generate(no_lessons), topic, topic_filename).call
        expect(result.success?).to eq(true)
      end
    end
  end
end
