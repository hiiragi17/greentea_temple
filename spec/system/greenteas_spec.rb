require 'rails_helper'

RSpec.describe 'Greenteas', type: :system do
  describe 'index greentea' do
    before do
      greenteas = build_list(:greentea, 30)
      Greentea.import greenteas
    end
    context 'access greentea#index' do
      it 'display greenteas per page' do
        visit greenteas_path
        # Kaminari の default_per_page（15）件が 1 ページに表示される
        expect(all('.card').count).to eq(Kaminari.config.default_per_page), '1ぺージに既定件数が表示されていません'
      end
      it 'pagination next page' do
        visit greenteas_path
        click_link '2'
        sleep 1
        expect(all('.card').count).to eq(Kaminari.config.default_per_page), 'ぺージネーションが機能していません'
      end
    end
  end
end
