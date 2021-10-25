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

  RSpec.shared_context 'a setting' do |named:|
    let!(:index) { client.create_index(random_uid) }
    let(:update_method_name) { "update_#{named}" }
    let(:setting_value_matcher) { method(:eq) }

    describe "##{named}" do
      it 'returns the default setting value' do
        setting_value = index.public_send(named)

        expect(setting_value).to eq(setting_default_value)
      end
    end

    describe "#update_#{named}" do
      it 'returns an updateId' do
        response = index.public_send(update_method_name, setting_updated_value)

        expect(response).to be_a(Hash)
        expect(response).to have_key('updateId')
        index.wait_for_pending_update(response['updateId'])
      end

      it "updates #{named}" do
        response = index.public_send(update_method_name, setting_updated_value)
        index.wait_for_pending_update(response['updateId'])

        expect(index.public_send(named)).to setting_value_matcher.call(setting_updated_value)
      end

      context 'when new setting is set to nil' do
        it 'resets to default setting value' do
          response = index.public_send(update_method_name, setting_updated_value)
          index.wait_for_pending_update(response['updateId'])

          response = index.public_send(update_method_name, nil)
          index.wait_for_pending_update(response['updateId'])

          expect(index.public_send(named)).to eq(setting_default_value)
        end
      end

      # TODO: may not be applicable to all settings
      # context 'when new setting value is invalid' do
      #   it 'fails to update' do
      #     response = index.public_send(update_method_name, setting_updated_value)
      #     index.wait_for_pending_update(response['updateId'])

      #     response = index.public_send(update_method_name, setting_invalid_value)
      #     index.wait_for_pending_update(response['updateId'])

      #     response = index.get_update_status(response['updateId'])
      #     expect(response.keys).to include('message')
      #     expect(response['errorCode']).to eq('invalid_request')
      #   end
      # end
    end

    describe "#reset_#{named}" do
      it 'resets setting back to default value' do
        response = index.public_send(update_method_name, setting_updated_value)
        index.wait_for_pending_update(response['updateId'])

        response = index.public_send("reset_#{named}")
        expect(response).to have_key('updateId')
        index.wait_for_pending_update(response['updateId'])

        expect(index.public_send(named)).to eq(setting_default_value)
      end
    end
  end

  context 'when setting ranking rules' do
    let(:setting_default_value) { default_ranking_rules }
    let(:setting_updated_value) { ['title:asc', 'words', 'typo'] }

    include_context 'a setting', named: 'ranking_rules'

    describe '#update_ranking_rules' do
      context 'when new ranking rule is invalid' do
        it 'fails to update' do
          response = index.update_ranking_rules(['typos'])
          index.wait_for_pending_update(response['updateId'])

          response = index.get_update_status(response['updateId'])
          expect(response.keys).to include('message')
          expect(response['errorCode']).to eq('invalid_request')
        end
      end
    end
  end

  context 'when setting distinct attribute' do
    let(:setting_default_value) { nil }
    let(:setting_updated_value) { 'title' }

    include_context 'a setting', named: 'distinct_attribute'
  end

  context 'when setting distinct attribute' do
    let(:setting_default_value) { ['*'] }
    let(:setting_updated_value) { ['title', 'description'] }

    include_context 'a setting', named: 'searchable_attributes'
  end

  context 'when setting displayed attributes' do
    let(:setting_default_value) { ['*'] }
    let(:setting_updated_value) { ['title', 'description'] }

    include_context 'a setting', named: 'displayed_attributes'
  end

  context 'when setting synonyms' do
    let(:setting_default_value) { {} }
    let(:setting_updated_value) do
      {
        'wow' => ['world of warcraft'],
        'wolverine' => ['xmen', 'logan'],
        'logan' => ['wolverine', 'xmen']
      }
    end

    include_context 'a setting', named: 'synonyms' do
      let(:setting_value_matcher) { method(:match_synonyms) }
    end

    describe '#update_synonyms' do
      it 'overwrites all synonyms' do
        response = index.update_synonyms(setting_updated_value)
        index.wait_for_pending_update(response['updateId'])

        response = index.update_synonyms(hp: ['harry potter'], 'harry potter': ['hp'])
        index.wait_for_pending_update(response['updateId'])

        synonyms = index.synonyms

        expect(synonyms).to match_synonyms(hp: ['harry potter'], 'harry potter': ['hp'])
      end
    end
  end

  context 'when setting stop words' do
    let(:setting_default_value) { [] }
    let(:setting_updated_value) { ['the', 'of'] }

    include_context 'a setting', named: 'stop_words' do
      let(:setting_value_matcher) { method(:match_array) }
    end

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

  context 'when setting filterable attributes' do
    let(:setting_default_value) { [] }
    let(:setting_updated_value) { ['title', 'description'] }

    include_context 'a setting', named: 'filterable_attributes' do
      let(:setting_value_matcher) { method(:match_array) }
    end
  end

  context 'when setting sortable attributes' do
    let(:setting_default_value) { [] }
    let(:setting_updated_value) { ['title', 'description'] }

    include_context 'a setting', named: 'sortable_attributes' do
      let(:setting_value_matcher) { method(:match_array) }
    end
  end

  context 'Index with primary-key' do
    let!(:index) { client.create_index(random_uid, primaryKey: 'id') }

    it 'gets the default values of settings' do
      response = index.settings
      expect(response).to be_a(Hash)
      expect(response.keys).to contain_exactly(*settings_keys)
      expect(response['rankingRules']).to eq(default_ranking_rules)
      expect(response['distinctAttribute']).to be_nil
      expect(response['searchableAttributes']).to eq(default_searchable_attributes)
      expect(response['displayedAttributes']).to eq(default_displayed_attributes)
      expect(response['stopWords']).to eq([])
      expect(response['synonyms']).to eq({})
    end

    it 'updates multiples settings at the same time' do
      response = index.update_settings(
        rankingRules: ['title:asc', 'typo'],
        distinctAttribute: 'title'
      )
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      settings = index.settings
      expect(settings['rankingRules']).to eq(['title:asc', 'typo'])
      expect(settings['distinctAttribute']).to eq('title')
      expect(settings['stopWords']).to be_empty
    end

    it 'updates one setting without reset the others' do
      response = index.update_settings(stopWords: ['the'])
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      settings = index.settings
      expect(settings['rankingRules']).to eq(default_ranking_rules)
      expect(settings['distinctAttribute']).to be_nil
      expect(settings['stopWords']).to eq(['the'])
      expect(settings['synonyms']).to be_empty
    end

    it 'resets all settings' do
      response = index.update_settings(
        rankingRules: ['title:asc', 'typo'],
        distinctAttribute: 'title',
        stopWords: ['the'],
        synonyms: {
          wow: ['world of warcraft']
        }
      )
      index.wait_for_pending_update(response['updateId'])

      response = index.reset_settings
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])

      settings = index.settings
      expect(settings['rankingRules']).to eq(default_ranking_rules)
      expect(settings['distinctAttribute']).to be_nil
      expect(settings['stopWords']).to be_empty
      expect(settings['synonyms']).to be_empty
    end
  end

  context 'Manipulation of searchable/displayed attributes with the primary-key' do
    let(:index) { client.index(random_uid) }

    it 'does not add document when there is no primary-key' do
      response = index.add_documents(title: 'Test')
      index.wait_for_pending_update(response['updateId'])
      response = index.get_update_status(response['updateId'])
      expect(response.keys).to include('message')
      expect(response['errorCode']).to eq('missing_primary_key')
    end

    it 'adds documents when there is a primary-key' do
      response = index.add_documents(objectId: 1, title: 'Test')
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.documents.count).to eq(1)
    end

    it 'resets searchable/displayed attributes' do
      response = index.update_displayed_attributes(['title', 'description'])
      index.wait_for_pending_update(response['updateId'])
      response = index.update_searchable_attributes(['title'])
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])

      response = index.reset_displayed_attributes
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')

      response = index.reset_searchable_attributes
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')

      expect(index.displayed_attributes).to eq(['*'])
      expect(index.searchable_attributes).to eq(['*'])
    end
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
