require 'rails_helper'

RSpec.describe Genre, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:genre)).to be_valid
    end
  end

  describe 'associations' do
    it 'has many greenteas through greentea_genres' do
      genre = create(:genre)
      greentea = create(:greentea)
      create(:greentea_genre, genre: genre, greentea: greentea)
      expect(genre.greenteas).to include(greentea)
    end

    it 'destroys dependent greentea_genres when destroyed' do
      genre = create(:genre)
      create(:greentea_genre, genre: genre, greentea: create(:greentea))
      expect { genre.destroy }.to change(GreenteaGenre, :count).by(-1)
    end
  end

  describe 'validations' do
    it 'is invalid without a name' do
      genre = build(:genre, name: nil)
      expect(genre).not_to be_valid
      expect(genre.errors[:name]).to be_present
    end
  end

  describe 'ransackable allowlist' do
    it 'allowlists id and name for attributes' do
      expect(described_class.ransackable_attributes).to match_array(%w[id name])
    end

    it 'allowlists no associations' do
      expect(described_class.ransackable_associations).to eq([])
    end
  end
end
