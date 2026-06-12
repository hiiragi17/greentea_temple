require 'rails_helper'

RSpec.describe Greentea, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:greentea)).to be_valid
    end
  end

  describe 'validations' do
    it 'is invalid without a name' do
      greentea = build(:greentea, name: nil)
      expect(greentea).not_to be_valid
      expect(greentea.errors[:name]).to be_present
    end

    it 'is invalid without a description' do
      greentea = build(:greentea, description: nil)
      expect(greentea).not_to be_valid
      expect(greentea.errors[:description]).to be_present
    end
  end

  describe 'associations' do
    it 'has many genres through greentea_genres' do
      greentea = create(:greentea)
      genre = create(:genre)
      create(:greentea_genre, greentea: greentea, genre: genre)
      expect(greentea.genres).to include(genre)
    end

    it 'has many users through greentea_likes' do
      greentea = create(:greentea)
      user = create(:user)
      create(:greentea_like, greentea: greentea, user: user)
      expect(greentea.users).to include(user)
    end

    it 'destroys dependent likes / genres / comments when destroyed' do
      greentea = create(:greentea)
      create(:greentea_genre, greentea: greentea, genre: create(:genre))
      create(:greentea_like, greentea: greentea, user: create(:user))
      create(:greenteacomment, greentea: greentea, user: create(:user))

      expect { greentea.destroy }
        .to change(GreenteaGenre, :count).by(-1)
        .and change(GreenteaLike, :count).by(-1)
        .and change(Greenteacomment, :count).by(-1)
    end
  end

  describe '#get_distance' do
    let(:greentea) { build(:greentea, latitude: 35.0, longitude: 135.0) }

    it 'returns 0 for the same coordinates' do
      expect(greentea.get_distance(35.0, 135.0)).to eq(0)
    end

    it 'returns a positive distance in meters rounded to the nearest 10' do
      distance = greentea.get_distance(34.99, 135.0)
      expect(distance).to be > 0
      expect((distance % 10)).to be_zero
    end
  end

  describe 'ransackable allowlist' do
    it 'allowlists name / description / address / access for attributes' do
      expect(described_class.ransackable_attributes).to match_array(%w[name description address access])
    end

    it 'allowlists genres / greentea_genres for associations' do
      expect(described_class.ransackable_associations).to match_array(%w[genres greentea_genres])
    end
  end
end
