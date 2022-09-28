require 'rails_helper'

RSpec.describe "Users", type: :system do
  describe 'user register' do
    before do
      visit new_user_path
    end
    context 'all clear' do
      it 'success register' do
        fill_in 'user[name]', with: '抹茶 神社'
        fill_in 'user[email]', with: 'greentea@example.com'
        fill_in 'user[password]', with: 'greentea123'
        fill_in 'user[password_confirmation]', with: 'greentea123'
        click_button '登録'
        expect(current_path).to eq root_path
      end
    end
    context 'no name' do
      it 'fail register' do
        fill_in 'user[name]', with: ''
        fill_in 'user[email]', with: 'greentea@example.com'
        fill_in 'user[password]', with: 'greentea123'
        fill_in 'user[password_confirmation]', with: 'greentea123'
        click_button '登録'
        expect(current_path).to eq root_path
        expect(page).to have_content('ユーザー名を入力してください')
      end
    end
    context 'no email' do
      it 'fail register' do
        fill_in 'user[name]', with: '抹茶 神社'
        fill_in 'user[email]', with: ''
        fill_in 'user[password]', with: 'greentea123'
        fill_in 'user[password_confirmation]', with: 'greentea123'
        click_button '登録'
        expect(current_path).to eq root_path
        expect(page).to have_content('メールアドレスを入力してください')
      end
    end
    context 'no password' do
      it 'fail register' do
        fill_in 'user[name]', with: '抹茶 神社'
        fill_in 'user[email]', with: 'greentea@example.com'
        fill_in 'user[password]', with: ''
        fill_in 'user[password_confirmation]', with: 'greentea123'
        click_button '登録'
        expect(current_path).to eq root_path
        expect(page).to have_content('パスワードは6文字以上で入力してください')
      end
    end
    context 'no password_confirmation' do
      it 'fail register' do
        fill_in 'user[name]', with: '抹茶 神社'
        fill_in 'user[email]', with: 'greentea@example.com'
        fill_in 'user[password]', with: 'greentea123'
        fill_in 'user[password_confirmation]', with: ''
        click_button '登録'
        expect(current_path).to eq root_path
        expect(page).to have_content('パスワード（確認用）を入力してください')
      end
    end
    context 'email duplication' do
      it 'fail register' do
        existed_user = create(:user)
        fill_in 'user[name]', with: '抹茶 神社'
        fill_in 'user[email]', with: existed_user.email
        fill_in 'user[password]', with: 'greentea123'
        fill_in 'user[password_confirmation]', with: 'greentea123'
        click_button '登録'
        expect(current_path).to eq root_path
        expect(page).to have_content('メールアドレスはすでに存在します')
      end
    end
    context 'パスワードが6文字未満' do
      it '登録に失敗する' do
        fill_in 'user[name]', with: '抹茶 神社'
        fill_in 'user[email]', with: 'greentea@example.com'
        fill_in 'user[password]', with: 'green'
        fill_in 'user[password_confirmation]', with: 'green'
        click_button '登録'
        expect(current_path).to eq root_path
        expect(page).to have_content('パスワードは6文字以上で入力してください')
      end
    end
  end
end
