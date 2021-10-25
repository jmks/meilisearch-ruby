# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Settings' do
  let(:default_ranking_rules) do
    [
      'words',
      'typo',
      'proximity',
      'attribute',
      'sort',
      'exactness'
    ]
  end
  let(:default_searchable_attributes) { ['*'] }
  let(:default_displayed_attributes) { ['*'] }
  let(:settings_keys) do
    [
      'rankingRules',
      'distinctAttribute',
      'searchableAttributes',
      'displayedAttributes',
      'stopWords',
      'synonyms',
      'filterableAttributes',
      'sortableAttributes'
    ]
  end

  describe '#settings' do
    let!(:index) { client.create_index(random_uid) }

    it 'returns default values of settings' do
      settings = index.settings

      expect(settings['rankingRules']).to eq(default_ranking_rules)
      expect(settings['distinctAttribute']).to be_nil
      expect(settings['searchableAttributes']).to eq(default_searchable_attributes)
      expect(settings['displayedAttributes']).to eq(default_displayed_attributes)
      expect(settings['stopWords']).to eq([])
      expect(settings['synonyms']).to eq({})
      expect(settings['filterableAttributes']).to eq([])
      expect(settings['sortableAttributes']).to eq([])
    end
  end

  describe '#update_settings' do
    let!(:index) { client.create_index(random_uid) }

    it 'updates a single setting' do
      response = index.update_settings(stopWords: ['the'])
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])

      settings = index.settings
      expect(settings['rankingRules']).to eq(default_ranking_rules)
      expect(settings['distinctAttribute']).to be_nil
      expect(settings['searchableAttributes']).to eq(default_searchable_attributes)
      expect(settings['displayedAttributes']).to eq(default_displayed_attributes)
      expect(settings['stopWords']).to eq(['the'])
      expect(settings['synonyms']).to eq({})
      expect(settings['filterableAttributes']).to eq([])
      expect(settings['sortableAttributes']).to eq([])
    end

    it 'updates multiple settings' do
      response = index.update_settings(
        rankingRules: ['title:asc', 'typo'],
        distinctAttribute: 'title'
      )
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])

      settings = index.settings
      expect(settings['rankingRules']).to eq(['title:asc', 'typo'])
      expect(settings['distinctAttribute']).to eq('title')
    end
  end

  describe '#reset_settings' do
    let!(:index) { client.create_index(random_uid) }

    it 'resets all settings' do
      response = index.update_settings(
        rankingRules: ['title:asc', 'typo'],
        distinctAttribute: 'title',
        stopWords: ['the', 'a'],
        synonyms: { wow: ['world of warcraft'] }
      )
      index.wait_for_pending_update(response['updateId'])

      response = index.reset_settings
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])

      settings = index.settings
      expect(settings['rankingRules']).to eq(default_ranking_rules)
      expect(settings['distinctAttribute']).to be_nil
      expect(settings['searchableAttributes']).to eq(default_searchable_attributes)
      expect(settings['displayedAttributes']).to eq(default_displayed_attributes)
      expect(settings['stopWords']).to eq([])
      expect(settings['synonyms']).to eq({})
      expect(settings['filterableAttributes']).to eq([])
      expect(settings['sortableAttributes']).to eq([])
    end
  end

  it_behaves_like 'an updateable setting', named: 'ranking_rules' do
    let(:default_value) { default_ranking_rules }
    let(:update_value) { ['title:asc', 'words', 'typo'] }

    context 'when new stop words are invalid' do
      it 'fails to update' do
        response = index.update_ranking_rules(update_value)
        index.wait_for_pending_update(response['updateId'])

        response = index.update_ranking_rules(['typos'])
        index.wait_for_pending_update(response['updateId'])

        response = index.get_update_status(response['updateId'])
        expect(response.keys).to include('message'), response.inspect
        expect(response['errorCode']).to eq('invalid_request')
      end
    end
  end

  it_behaves_like 'an updateable setting', named: 'distinct_attribute' do
    let(:default_value) { nil }
    let(:update_value) { 'title' }
  end

  it_behaves_like 'an updateable setting', named: 'searchable_attributes' do
    let(:default_value) { ['*'] }
    let(:update_value) { ['title', 'description'] }
  end

  it_behaves_like 'an updateable setting', named: 'displayed_attributes' do
    let(:default_value) { ['*'] }
    let(:update_value) { ['title', 'description'] }
  end

  it_behaves_like 'an updateable setting', named: 'synonyms' do
    let(:default_value) { {} }
    let(:update_value) do
      {
        'wow' => ['world of warcraft'],
        'wolverine' => ['xmen', 'logan'],
        'logan' => ['wolverine', 'xmen']
      }
    end
    let(:matcher) { method(:match_synonyms) }

    describe '#update_synonyms' do
      it 'overwrites all synonyms' do
        response = index.update_synonyms(update_value)
        index.wait_for_pending_update(response['updateId'])

        response = index.update_synonyms(hp: ['harry potter'], 'harry potter': ['hp'])
        index.wait_for_pending_update(response['updateId'])

        synonyms = index.synonyms

        expect(synonyms).to match_synonyms(hp: ['harry potter'], 'harry potter': ['hp'])
      end
    end
  end

  it_behaves_like 'an updateable setting', named: 'stop_words' do
    let(:default_value) { [] }
    let(:update_value) { ['the', 'of'] }
    let(:matcher) { method(:match_array) }
    let(:setting_invalid_value) { { test: 'test' } }

    describe '#update_stop_words' do
      it 'updates from a string' do
        response = index.update_stop_words('a')
        index.wait_for_pending_update(response['updateId'])

        stop_words = index.stop_words

        expect(stop_words).to be_a(Array)
        expect(stop_words).to contain_exactly('a')
      end

      context 'when invalid' do
        it 'returns an error' do
          expect do
            index.update_stop_words(test: 'test')
          end.to raise_bad_request_meilisearch_api_error
        end
      end
    end
  end

  it_behaves_like 'an updateable setting', named: 'filterable_attributes' do
    let(:default_value) { [] }
    let(:update_value) { ['title', 'description'] }
    let(:matcher) { method(:match_array) }
  end

  it_behaves_like 'an updateable setting', named: 'sortable_attributes' do
    let(:default_value) { [] }
    let(:update_value) { ['title', 'description'] }
    let(:matcher) { method(:match_array) }
  end

  context 'Aliases' do
    let!(:index) { client.create_index(random_uid) }

    it 'works with method aliases' do
      expect(index.method(:settings) == index.method(:get_settings)).to be_truthy
      expect(index.method(:ranking_rules) == index.method(:get_ranking_rules)).to be_truthy
      expect(index.method(:distinct_attribute) == index.method(:get_distinct_attribute)).to be_truthy
      expect(index.method(:searchable_attributes) == index.method(:get_searchable_attributes)).to be_truthy
      expect(index.method(:displayed_attributes) == index.method(:get_displayed_attributes)).to be_truthy
      expect(index.method(:synonyms) == index.method(:get_synonyms)).to be_truthy
      expect(index.method(:stop_words) == index.method(:get_stop_words)).to be_truthy
      expect(index.method(:filterable_attributes) == index.method(:get_filterable_attributes)).to be_truthy
    end
  end
end
