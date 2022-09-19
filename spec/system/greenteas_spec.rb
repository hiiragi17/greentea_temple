require 'rails_helper'

RSpec.describe 'Greenteas', type: :system do
  describe 'index greentea' do
    before do
      greenteas = build_list(:greentea, 30)
      Greentea.import greenteas
    end
    context 'access greentea#index' do
      it 'display greentea 10shop' do
        visit greenteas_path
        expect(all('.card').count).to eq(10), '1ぺージに10件表示されていません'
      end
      it 'pagination 10count' do
        visit greenteas_path
        click_link '2'
        sleep 1
        expect(all('.card').count).to eq(10), 'ぺージネーションが機能していません'
      end
    end
  end
end
