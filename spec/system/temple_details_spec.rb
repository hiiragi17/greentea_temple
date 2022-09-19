require 'rails_helper'

RSpec.describe 'TempleDetails', type: :system do
  let!(:temple) { create(:temple) }
  let!(:near_greentea1) { create(:greentea, latitude: 34.967653, longitude: 135.774144) }
  let!(:near_greentea2) { create(:greentea, latitude: 34.967673, longitude: 135.774154) }
  let!(:far_greentea) { create(:greentea, latitude: 35.6476602, longitude: 139.741758) }
  describe 'show temple' do
    context 'access temple#show' do
      it 'display temple_information' do
        visit temple_path(temple)
        expect(page).to have_content(temple.name), '神社仏閣が表示されていません'
        expect(page).to have_content(temple.description), '説明が表示されていません'
        expect(page).to have_content(temple.phone_number), '電話番号が表示されていません'
        expect(page).to have_content(temple.address), '住所が表示されていません'
        expect(page).to have_content(temple.access), 'アクセスが表示されていません'
        expect(page).to have_content(temple.business_hours), '営業時間が表示されていません'
        expect(page).to have_content(temple.homepage), 'ホームページが表示されていません'
        expect(page).to have_content(temple.holiday), '休日が表示されていません'
      end
      xit 'display near_greentea' do
        visit temple_path(temple)
        expect(all('.card').count).to eq(2)
        expect(page).to have_content(near_greentea1), '近い抹茶スイーツ店が表示されていません'
        expect(page).to have_content(near_greentea2), '近い抹茶スイーツ店が表示されていません'
        expect(page).not_to have_content(far_greentea), '近くない抹茶スイーツ店が表示されています'
      end
      it 'show near_greentea' do
        visit temple_path(temple)
        click_link near_greentea1.name
        expect(current_path).to eq(greentea_path(near_greentea1))
      end
    end
  end
end
