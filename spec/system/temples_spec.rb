require 'rails_helper'

RSpec.describe 'Temples', type: :system do
  describe 'index temple' do
    before do
      temples = build_list(:temple, 30)
      Temple.import temples
    end
    context 'access temple#index' do
      it 'display temple 10shop' do
        visit temples_path
        expect(all('.card').count).to eq(10), '1ぺージに10件表示されていません'
      end
      it 'pagination 10count' do
        visit temples_path
        click_link '2'
        sleep 1
        expect(all('.card').count).to eq(10), 'ぺージネーションが機能していません'
      end
    end
  end
end
