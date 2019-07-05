require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User logs in', :vcr, type: :feature, js: true do
  include_context 'api_data'
  include_context 'wonde_test_data'
  include_context 'default_creates'

  context 'when looking at the page' do
    subject { page }

    before { visit root_path }

    it { is_expected.to have_button('Login') }
    it { is_expected.to have_content('TENJIN') }
  end

  context 'when logging in' do
    before do
      visit root_path
      student
    end

    it 'pops up the student login when needed' do
      click_button 'Login'
      expect(page).to have_content('Login').and have_content('Password')
    end

    it 'logs in a student using an username' do
      log_in_through_front_page(student.username, student.password)
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end

    it 'logs in a teacher using an email' do
      log_in_through_front_page(teacher.username, teacher.password)
      expect(page).to have_content(teacher.forename).and have_content(teacher.surname)
    end

    it 'logs in using Wonde single sign on' do
      stub_omniauth
      student_wonde
      click_button 'Login'
      click_link 'Sign in with Wonde'
      expect(page).to have_content(student_wonde.forename).and have_content(student_wonde.surname)
    end

    it 'redirects to dashboard if they are already signed in' do
      sign_in student
      visit('/')
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end
  end

  it 'displays log in error messages' do
    visit root_path
    stub_omniauth
    click_button 'Login'
    click_link 'Sign in with Wonde'
    expect(page).to have_text('Your account has not been found')
  end

  it 'allows teachers to login via the devise login page'
end
