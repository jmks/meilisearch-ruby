# frozen_string_literal: true

RSpec.shared_context 'an updateable setting' do |named:|
  let!(:index) { client.create_index(random_uid) }
  let(:matcher) { method(:eq) }
  let(:update_method_name) { "update_#{named}" }

  describe "##{named}" do
    it 'returns the default setting value' do
      setting_value = index.public_send(named)

      expect(setting_value).to eq(default_value)
    end
  end

  describe "#update_#{named}" do
    it 'returns an updateId' do
      response = index.public_send(update_method_name, update_value)

      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
    end

    it "updates #{named}" do
      response = index.public_send(update_method_name, update_value)
      index.wait_for_pending_update(response['updateId'])

      expect(index.public_send(named)).to matcher.call(update_value)
    end

    context 'when new setting is set to nil' do
      it 'resets to default setting value' do
        response = index.public_send(update_method_name, update_value)
        index.wait_for_pending_update(response['updateId'])

        response = index.public_send(update_method_name, nil)
        index.wait_for_pending_update(response['updateId'])

        expect(index.public_send(named)).to eq(default_value)
      end
    end
  end

  describe "#reset_#{named}" do
    it 'resets setting back to default value' do
      response = index.public_send(update_method_name, update_value)
      index.wait_for_pending_update(response['updateId'])

      response = index.public_send("reset_#{named}")
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])

      expect(index.public_send(named)).to eq(default_value)
    end
  end
end
