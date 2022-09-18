require 'rails_helper'

RSpec.describe "GreenteaDetails", type: :system do
  let!(:greentea) { create(:greentea) }
  let!(:near_temple1) { create(:temple, latitude:34.9676, longitude:135.7741) }
  let!(:near_temple2) { create(:temple, latitude:34.9676, longitude:135.7741) }
  let!(:far_temple) { create(:temple, latitude:35.6476602, longitude:139.741758) }
  describe 'show greentea' do
    context 'access greentea#show' do
      it 'display greentea_information' do
        visit greentea_path(greentea)
        expect(page).to have_content(greentea.name),'抹茶スイーツ店が表示されていません'
        expect(page).to have_content(greentea.description),'説明が表示されていません'
        expect(page).to have_content(greentea.phone_number),'電話番号が表示されていません'
        expect(page).to have_content(greentea.address),'住所が表示されていません'
        expect(page).to have_content(greentea.access),'アクセスが表示されていません'
        expect(page).to have_content(greentea.business_hours),'営業時間が表示されていません'
        expect(page).to have_content(greentea.homepage),'ホームページが表示されていません'
        expect(page).to have_content(greentea.holiday),'休日が表示されていません'
      end
      it 'display near_temple' do
        visit greentea_path(greentea)
        expect(Temple.count).to eq(2)
        expect(page).to have_content(near_temple1),'近い神社仏閣が表示されていません'
        expect(page).to have_content(near_temple2),'近い神社仏閣が表示されていません'
        expect(page).not_to have_content(far_temple),'近くない神社仏閣が表示されています'
      end
      it 'show near_temple' do
        visit greentea_path(greentea)
        click_link near_temple1.name
        expect(current_path).to eq(temple_path(near_temple1))
      end
    end
  end
end
