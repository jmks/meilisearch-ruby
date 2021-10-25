# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Indexes' do
  describe '#create_index' do
    it 'creates an index without a primary key' do
      index = client.create_index('new_index')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('new_index')
      expect(index.primary_key).to be_nil
      expect(index.fetch_primary_key).to be_nil
    end

    it 'creates an index with a primary key' do
      index = client.create_index('new_index', primaryKey: 'primary_key')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('new_index')
      expect(index.primary_key).to eq('primary_key')
      expect(index.fetch_primary_key).to eq('primary_key')
    end

    it 'creates an index with a snake_case primary key option' do
      index = client.create_index('new_index', primary_key: 'primary_key')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('new_index')
      expect(index.primary_key).to eq('primary_key')
      expect(index.fetch_primary_key).to eq('primary_key')
    end

    context 'when uid is provided as an option' do
      it 'creates the index, ignoring the uid option' do
        index = client.create_index(
          'new_index',
          primaryKey: 'primary_key',
          uid: 'not_primary_key'
        )

        expect(index).to be_a(MeiliSearch::Index)
        expect(index.uid).to eq('new_index')
        expect(index.primary_key).to eq('primary_key')
        expect(index.fetch_primary_key).to eq('primary_key')
      end
    end

    context 'when an index with a given uid already exists' do
      it 'raises an error' do
        client.create_index('existing_index')

        expect do
          client.create_index('existing_index')
        end.to raise_meilisearch_api_error_with(400, 'index_already_exists', 'invalid_request_error')
      end
    end

    context 'when the uid format is invalid' do
      it 'raises an error' do
        expect do
          client.create_index('two words')
        end.to raise_meilisearch_api_error_with(400, 'invalid_index_uid', 'invalid_request_error')
      end
    end
  end

  describe '#get_or_create_index' do
    it 'creates a new index' do
      expect do
        new_index = client.get_or_create_index('new_index')

        expect(new_index).to be_a(MeiliSearch::Index)
      end.to change { client.indexes.length }.by(1)

      found_index = client.fetch_index('new_index')
      expect(found_index.uid).to eq('new_index')
      expect(found_index.primary_key).to be_nil
    end

    it 'creates a new index with a primary key' do
      expect do
        index = client.get_or_create_index('new_index', primaryKey: 'primary_key')

        expect(index).to be_a(MeiliSearch::Index)
      end.to change { client.indexes.length }.by(1)
    end

    it 'gets an index that already exists' do
      client.create_index('existing_index')

      expect do
        client.get_or_create_index('existing_index')
      end.not_to(change { client.indexes.length })
    end
  end

  describe '#indexes' do
    it 'returns MeiliSearch::Index objects' do
      client.create_index('index')

      response = client.indexes.first

      expect(response).to be_a(MeiliSearch::Index)
    end

    it 'gets list of indexes' do
      ['first_index', 'second_index', 'third_index'].each { |name| client.create_index(name) }

      indexes = client.indexes

      expect(indexes).to be_a(Array)
      expect(indexes.length).to eq(3)
      uids = indexes.map(&:uid)
      expect(uids).to contain_exactly('first_index', 'second_index', 'third_index')
    end
  end

  describe '#raw_indexes' do
    it 'gets list of raw indexes' do
      ['first_index', 'second_index', 'third_index'].each { |name| client.create_index(name) }

      indexes = client.raw_indexes

      expect(indexes).to be_a(Array)
      expect(indexes.length).to eq(3)
      uids = indexes.map { |elem| elem['uid'] }
      expect(uids).to contain_exactly('first_index', 'second_index', 'third_index')
    end
  end

  describe '#fetch_index' do
    it 'fetches index by uid' do
      client.create_index('new_index', primaryKey: 'primary_key')

      fetched_index = client.fetch_index('new_index')

      expect(fetched_index).to be_a(MeiliSearch::Index)
      expect(fetched_index.uid).to eq('new_index')
      expect(fetched_index.primary_key).to eq('primary_key')
      expect(fetched_index.fetch_primary_key).to eq('primary_key')
    end
  end

  describe '#index' do
    it 'returns an index object with the provided uid' do
      client.create_index('existing_index', primaryKey: 'primary_key')

      # this index is in memory, without metadata from server
      index = client.index('existing_index')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('existing_index')
      expect(index.primary_key).to be_nil

      # fetch primary key metadata from server
      expect(index.fetch_primary_key).to eq('primary_key')
      expect(index.primary_key).to eq('primary_key')
    end
  end

  describe '#delete_index' do
    context 'when the index exists' do
      it 'deletes the index' do
        client.create_index('existing_index')

        expect(client.delete_index('existing_index')).to be_nil
        expect { client.fetch_index('existing_index') }.to raise_index_not_found_meilisearch_api_error
      end
    end

    context 'when the index does not exist' do
      it 'raises an index not found error' do
        expect { client.delete_index('index_does_not_exist') }.to raise_index_not_found_meilisearch_api_error
      end
    end
  end
end
