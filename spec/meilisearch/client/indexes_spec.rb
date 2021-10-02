# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Indexes', :clear_indexes do
  let(:client) { MeiliSearch::Client.new($URL, $MASTER_KEY) }

  describe '#create_index' do
    it 'creates an index without a primary key' do
      index = client.create_index('index_without_primary_key')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('index_without_primary_key')
      expect(index.primary_key).to be_nil
      expect(index.fetch_primary_key).to be_nil
    end

    it 'creates an index with a primary key' do
      index = client.create_index('index_with_primary_key', primaryKey: 'primary_key')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('index_with_primary_key')
      expect(index.primary_key).to eq('primary_key')
      expect(index.fetch_primary_key).to eq('primary_key')
    end

    context 'when uid is provided as an option' do
      it 'creates an index with the primary key' do
        index = client.create_index(
          'index_with_uid_from_primary_key',
          primaryKey: 'primary_key',
          uid: 'not_primary_key'
        )

        expect(index).to be_a(MeiliSearch::Index)
        expect(index.uid).to eq('index_with_uid_from_primary_key')
        expect(index.primary_key).to eq('primary_key')
        expect(index.fetch_primary_key).to eq('primary_key')
      end
    end

    context 'when an index with a given uid already exists' do
      it 'raises an error' do
        _existing_index = client.create_index('create_index_existing')

        expect do
          client.create_index('create_index_existing')
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

  describe '#get_or_create' do
    it 'creates a new index' do
      expect do
        index = client.get_or_create_index('get_or_create_new_index')

        expect(index).to be_a(MeiliSearch::Index)
      end.to change { client.indexes.length }.by(1)

      found_index = client.fetch_index('get_or_create_new_index')
      expect(found_index.uid).to eq('get_or_create_new_index')
      expect(found_index.primary_key).to be_nil
    end

    it 'creates a new index with a primary key' do
      expect do
        index = client.get_or_create_index('get_or_create_new_index_with_primary_key', primaryKey: 'primary_key')

        expect(index).to be_a(MeiliSearch::Index)
      end.to change { client.indexes.length }.by(1)

      found_index = client.fetch_index('get_or_create_new_index_with_primary_key')
      expect(found_index.uid).to eq('get_or_create_new_index_with_primary_key')
      expect(found_index.primary_key).to eq('primary_key')
    end

    it 'gets an index that already exists' do
      _existing_index = client.create_index('get_or_create_existing_index')

      expect do
        client.get_or_create_index('get_or_create_existing_index')
      end.not_to(change { client.indexes.length })
    end
  end

  describe '#indexes' do
    it 'gets list of indexes' do
      client.create_index('list_indexes_first')
      client.create_index('list_indexes_second')
      client.create_index('list_indexes_third')

      indexes = client.indexes

      expect(indexes).to be_a(Array)
      expect(indexes.length).to be(3)
      uids = indexes.map { |elem| elem['uid'] }
      expect(uids).to contain_exactly('list_indexes_first', 'list_indexes_second', 'list_indexes_third')
    end
  end

  describe '#fetch_index' do
    it 'fetches index by uid' do
      client.create_index('fetch_index', primaryKey: 'primary_key')

      fetched_index = client.fetch_index('fetch_index')

      expect(fetched_index).to be_a(MeiliSearch::Index)
      expect(fetched_index.uid).to eq('fetch_index')
      expect(fetched_index.primary_key).to eq('primary_key')
      expect(fetched_index.fetch_primary_key).to eq('primary_key')
    end
  end

  describe '#index' do
    it 'returns an index object with the provided uid' do
      _existing_index = client.create_index('fetch_index_existing', primaryKey: 'primary_key')

      # this index is in memory, without metadata from server
      index = client.index('fetch_index_existing')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('fetch_index_existing')
      expect(index.primary_key).to be_nil

      # fetch primary key metadata from server
      expect(index.fetch_primary_key).to eq('primary_key')
      expect(index.primary_key).to eq('primary_key')
    end
  end

  describe '#delete_index' do
    context 'when the index exists' do
      it 'deletes the index' do
        _existing_index = client.create_index('delete_index_existing')

        expect(client.delete_index('delete_index_existing')).to be_nil
        expect { client.fetch_index('delete_index_existing') }.to raise_index_not_found_meilisearch_api_error
      end
    end

    context 'when the index does not exist' do
      it 'raises an index not found error' do
        expect { client.delete_index('delete_index_does_not_exist') }.to raise_index_not_found_meilisearch_api_error
      end
    end
  end
end
