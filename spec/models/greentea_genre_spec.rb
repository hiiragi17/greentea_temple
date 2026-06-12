require 'rails_helper'

RSpec.describe GreenteaGenre, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:greentea_genre)).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a greentea and a genre' do
      greentea_genre = create(:greentea_genre)
      expect(greentea_genre.greentea).to be_a(Greentea)
      expect(greentea_genre.genre).to be_a(Genre)
    end
  end

  describe 'ransackable allowlist' do
    it 'allowlists id / greentea_id / genre_id for attributes' do
      expect(described_class.ransackable_attributes).to match_array(%w[id greentea_id genre_id])
    end

    it 'allowlists greentea / genre for associations' do
      expect(described_class.ransackable_associations).to match_array(%w[greentea genre])
    end
  end
end
