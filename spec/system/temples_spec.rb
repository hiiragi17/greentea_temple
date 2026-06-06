require 'rails_helper'

RSpec.describe 'Temples', type: :system do
  describe 'index temple' do
    before do
      temples = build_list(:temple, 30)
      Temple.import temples
    end
    context 'access temple#index' do
      it 'display temples per page' do
        visit temples_path
        # Kaminari の default_per_page（15）件が 1 ページに表示される
        expect(all('.card').count).to eq(Kaminari.config.default_per_page), '1ぺージに既定件数が表示されていません'
      end
      it 'pagination next page' do
        visit temples_path
        click_link '2'
        sleep 1
        expect(all('.card').count).to eq(Kaminari.config.default_per_page), 'ぺージネーションが機能していません'
      end
    end
  end
end
