# frozen_string_literal: true

RSpec::Matchers.define :match_synonyms do |expected|
  match do |actual|
    matching_keys?(actual, expected) && matching_values?(actual, expected)
  end

  private

  def matching_keys?(actual, expected)
    actual_keys = actual.keys.map(&:to_s)
    expected_keys = expected.keys.map(&:to_s)

    actual_keys.sort == expected_keys.sort
  end

  def matching_values?(actual, expected)
    actual.all? do |key, synonyms|
      synonym = key.to_s
      expected_synonyms = expected[key.to_sym] || expected[synonym] || []

      synonyms.sort == expected_synonyms.sort
    end
  end
end
