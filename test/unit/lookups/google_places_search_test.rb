# encoding: utf-8
require 'test_helper'
require 'json'

class GooglePlacesSearchTest < GeocoderTestCase

  def setup
    super
    Geocoder.configure(lookup: :google_places_search)
    set_api_key!(:google_places_search)
  end

  def test_google_places_search_result_contains_place_id
    assert_equal "ChIJhRwB-yFawokR5Phil-QQ3zM", madison_square_garden.place_id
  end

  def test_google_places_search_result_contains_latitude
    assert_equal madison_square_garden.latitude, 40.75050450000001
  end

  def test_google_places_search_result_contains_longitude
    assert_equal madison_square_garden.longitude, -73.9934387
  end

  def test_google_places_search_result_contains_rating
    assert_equal 4.5, madison_square_garden.rating
  end

  def test_google_places_search_result_contains_types
    # Note: Types might differ slightly with v1 API, adjust if needed based on actual stubbed response
    assert_equal %w(stadium point_of_interest establishment), madison_square_garden.types
  end

  def test_google_places_search_query_url_contains_language
    url = lookup.query_url(Geocoder::Query.new("some-address", language: "de"))
    assert_match(/languageCode=de/, url) # Changed from language= to languageCode=
  end

  def test_google_places_search_query_url_always_uses_https
    url = lookup.query_url(Geocoder::Query.new("some-address"))
    assert_match(%r{^https://}, url)
  end

  def test_google_places_search_body_contains_specific_fields_when_given
    fields = %w[formattedAddress id]
    query = Geocoder::Query.new("some-address", fields: fields)
    body = JSON.parse(lookup.send(:request_body_json, query))
    assert_equal fields.sort, body['includedFields']['paths'].sort
  end

  def test_google_places_search_body_contains_specific_fields_when_configured
    fields = %w[businessStatus geometry photos] # Use valid v1 field names
    Geocoder.configure(google_places_search: {fields: fields})
    query = Geocoder::Query.new("some-address")
    body = JSON.parse(lookup.send(:request_body_json, query))
    assert_equal fields.sort, body['includedFields']['paths'].sort
    Geocoder.configure(google_places_search: {})
  end

  def test_google_places_search_body_omits_fields_when_nil_given
    query = Geocoder::Query.new("some-address", fields: nil)
    body = JSON.parse(lookup.send(:request_body_json, query))
    # When fields: nil is passed, format_fields returns nil, so includedFields should not be set
    assert_nil body['includedFields']
  end

  def test_google_places_search_body_omits_fields_when_nil_configured
    Geocoder.configure(google_places_search: {fields: nil})
    query = Geocoder::Query.new("some-address")
    body = JSON.parse(lookup.send(:request_body_json, query))
    # When fields: nil is configured, format_fields returns nil, so includedFields should not be set
    assert_nil body['includedFields']
    Geocoder.configure(google_places_search: {})
  end

  def test_google_places_search_body_contains_text_query
    query = Geocoder::Query.new("some-address")
    body = JSON.parse(lookup.send(:request_body_json, query))
    assert_equal "some-address", body['textQuery']
  end

  def test_google_places_search_body_omits_locationbias_by_default
    query = Geocoder::Query.new("some-address")
    body = JSON.parse(lookup.send(:request_body_json, query))
    assert_nil body['locationBias']
  end

  def test_google_places_search_body_contains_locationbias_when_configured
    bias_string = "point:-36.8509,174.7645"
    Geocoder.configure(google_places_search: {locationbias: bias_string})
    query = Geocoder::Query.new("some-address")
    body = JSON.parse(lookup.send(:request_body_json, query))
    assert_equal bias_string, body['locationBias']
    Geocoder.configure(google_places_search: {})
  end

  def test_google_places_search_body_contains_locationbias_when_given
    bias_string = "point:-36.8509,174.7645"
    query = Geocoder::Query.new("some-address", locationbias: bias_string)
    body = JSON.parse(lookup.send(:request_body_json, query))
    assert_equal bias_string, body['locationBias']
  end

  def test_google_places_search_body_uses_given_locationbias_over_configured
    configured_bias = "point:37.4275,-122.1697"
    given_bias = "point:-36.8509,174.7645"
    Geocoder.configure(google_places_search: {locationbias: configured_bias})
    query = Geocoder::Query.new("some-address", locationbias: given_bias)
    body = JSON.parse(lookup.send(:request_body_json, query))
    assert_equal given_bias, body['locationBias']
    Geocoder.configure(google_places_search: {})
  end

  def test_google_places_search_body_omits_locationbias_when_nil_given
    Geocoder.configure(google_places_search: {locationbias: "point:37.4275,-122.1697"})
    query = Geocoder::Query.new("some-address", locationbias: nil)
    body = JSON.parse(lookup.send(:request_body_json, query))
    assert_nil body['locationBias']
    Geocoder.configure(google_places_search: {})
  end

  def test_google_places_search_uses_v1_search_text_endpoint
    # Check the base URL part (excluding query params)
    base_url = lookup.query_url(Geocoder::Query.new("some-address")).split('?').first
    assert_match(%r{/v1/places:searchText$}, base_url)
  end

  private

  def lookup
    Geocoder::Lookup::GooglePlacesSearch.new
  end

  def madison_square_garden
    # Ensure the stubbed response for this matches the v1 API structure
    Geocoder.search("Madison Square Garden").first
  end
end
