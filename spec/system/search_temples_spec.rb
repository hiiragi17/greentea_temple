require 'rails_helper'

RSpec.describe "SearchTemples", type: :system do
  describe 'search temple' do
    let!(:temple_gan) { create(:temple, :gan, name:'神社仏閣願号社') }
    let!(:temple_kouyou) { create(:temple, :kouyou, name:'神社仏閣本') }
    let!(:temple_husimi) { create(:temple, :husimi,  name:'神社仏閣清') }
    let!(:temple_uzi) { create(:temple, :uzi,  name:'神社仏閣春') }
    let!(:temple) { create(:temple, name:'神社仏閣左京区') }
    let!(:area) { create(:area) }
    let!(:temple_area) { create(:temple_area, temple:temple, area:area) }
    context 'search name' do
      it 'display name-temple' do
        visit temples_path
        fill_in('q[name_or_description_or_address_or_access_cont]', with: '願')
        click_button '検索'
        expect(page).to have_content(temple_gan.name), '検索が失敗しています'
        expect(page).not_to have_content(temple_uzi.name), '検索が失敗しています'
      end
    end
    context 'search description' do
      it 'display description-temple' do
        visit temples_path
        fill_in('q[name_or_description_or_address_or_access_cont]', with: '紅葉')
        click_button '検索'
        expect(page).to have_content(temple_kouyou.name), '検索が失敗しています'
        expect(page).not_to have_content(temple_uzi.name), '検索が失敗しています'
      end
    end
    context 'search address' do
      it 'display address-temple' do
        visit temples_path
        fill_in('q[name_or_description_or_address_or_access_cont]', with: '伏見')
        click_button '検索'
        expect(page).to have_content(temple_husimi.name), '検索が失敗しています'
        expect(page).not_to have_content(temple_kouyou.name), '検索が失敗しています'
      end
    end
    context 'search access' do
      it 'display address-temple' do
        visit temples_path
        fill_in('q[name_or_description_or_address_or_access_cont]', with: '宇治')
        click_button '検索'
        expect(page).to have_content(temple_uzi.name), '検索が失敗しています'
        expect(page).not_to have_content(temple_husimi.name), '検索が失敗しています'
      end
    end
    context 'search area' do
      it 'display temple-area' do
        visit temples_path
        check '京都市左京区'
        click_button '検索'
        expect(page).to have_content(temple.name), '検索が失敗しています'
        expect(page).not_to have_content(temple_uzi.name), '検索が失敗しています'
      end
    end
  end
end
