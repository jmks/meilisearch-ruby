# frozen_string_literal: true

RSpec.describe 'Match synonyms matcher' do
  context 'when synonyms hashes are similar' do
    it 'matches on symbol or string keys' do
      expect({ 'wolverine' => ['logan', 'weapon x'] }).to match_synonyms({ wolverine: ['logan', 'weapon x'] })
      expect({ wolverine: ['logan', 'weapon x'] }).to match_synonyms({ 'wolverine' => ['logan', 'weapon x'] })
    end

    it 'matches on synonym lists in any order' do
      expect({ 'wolverine' => ['weapon x', 'logan'] }).to match_synonyms({ wolverine: ['logan', 'weapon x'] })
    end
  end

  context 'when synonyms do not match' do
    it 'does not match' do
      expect({}).not_to match_synonyms({ wolverine: ['logan'] })
      expect({ wolverine: ['logan'] }).not_to match_synonyms({})
      expect({ wolverine: ['logan'] }).not_to match_synonyms({ 'wolverine' => ['weapon x'] })
    end
  end
end
