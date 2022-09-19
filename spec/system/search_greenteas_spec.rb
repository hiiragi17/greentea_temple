require 'rails_helper'

RSpec.describe "SearchGreenteas", type: :system do
  describe 'search greentea' do
    let!(:greentea_gion) { create(:greentea, :gion, name:'抹茶スイーツ祇園') }
    let!(:greentea_cake) { create(:greentea, :cake, name:'抹茶スイーツ努力') }
    let!(:greentea_husimi) { create(:greentea, :husimi,  name:'抹茶スイーツ希望') }
    let!(:greentea_uzi) { create(:greentea, :uzi,  name:'抹茶スイーツ夢') }
    let!(:greentea) { create(:greentea, name:'抹茶スイーツジャンル') }
    let!(:genre) { create(:genre) }
    let!(:greentea_genre) { create(:greentea_genre, greentea:greentea, genre:genre) }
    context 'search name' do
      it 'display name-greentea' do
        visit greenteas_path
        fill_in('q[name_or_description_or_address_or_access_cont]', with: '祇園')
        click_button '検索'
        expect(page).to have_content(greentea_gion.name), '検索が失敗しています'
        expect(page).not_to have_content(greentea_uzi.name), '検索が失敗しています'
      end
    end
    context 'search description' do
      it 'display description-greentea' do
        visit greenteas_path
        fill_in('q[name_or_description_or_address_or_access_cont]', with: 'ケーキ')
        click_button '検索'
        expect(page).to have_content(greentea_cake.name), '検索が失敗しています'
        expect(page).not_to have_content(greentea_uzi.name), '検索が失敗しています'
      end
    end
    context 'search address' do
      it 'display address-greentea' do
        visit greenteas_path
        fill_in('q[name_or_description_or_address_or_access_cont]', with: '伏見')
        click_button '検索'
        expect(page).to have_content(greentea_husimi.name), '検索が失敗しています'
        expect(page).not_to have_content(greentea_cake.name), '検索が失敗しています'
      end
    end
    context 'search access' do
      it 'display address-greentea' do
        visit greenteas_path
        fill_in('q[name_or_description_or_address_or_access_cont]', with: '宇治')
        click_button '検索'
        expect(page).to have_content(greentea_uzi.name), '検索が失敗しています'
        expect(page).not_to have_content(greentea_husimi.name), '検索が失敗しています'
      end
    end
    context 'search genre' do
      it 'display genre-greentea' do
        visit greenteas_path
        check 'パフェ'
        click_button '検索'
        expect(page).to have_content(greentea.name), '検索が失敗しています'
        expect(page).not_to have_content(greentea_uzi.name), '検索が失敗しています'
      end
    end
  end
end