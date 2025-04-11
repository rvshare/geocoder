require "geocoder/lookups/base"
require "geocoder/results/google_places_details"
require 'logger'

module Geocoder::Lookup
  class GooglePlacesDetails < Base
    def name
      "Google Places Details"
    end

    def required_api_key_parts
      ["key"]
    end

    def supported_protocols
      [:https]
    end

    private

    def base_url
      "#{protocol}://places.googleapis.com/v1/places"
    end

    def base_query_url(query)
      # Check if place_id already has places/ prefix
      place_id = query.text
      unless place_id.start_with?('places/')
        place_id = "#{place_id}"
      end

      # Encode the place ID to handle special characters
      encoded_place_id = URI.encode_www_form_component(place_id)
      "#{base_url}/#{encoded_place_id}?"
    end

    def valid_response?(response)
      json = parse_json(response.body)
      error_status = json.dig('error', 'status') if json
      super(response) and error_status.nil?
    end

    def results(query)
      doc = fetch_data(query)
      return [] unless doc

      if doc['error']
        case doc['error']['status']
        when 'RESOURCE_EXHAUSTED'
          raise_error(Geocoder::OverQueryLimitError) ||
            Geocoder.log(:warn, "#{name} API error: resource exhausted.")
        when 'PERMISSION_DENIED'
          raise_error(Geocoder::RequestDenied, doc['error']['message']) ||
            Geocoder.log(:warn, "#{name} API error: permission denied (#{doc['error']['message']}).")
        when 'INVALID_ARGUMENT'
          raise_error(Geocoder::InvalidRequest, doc['error']['message']) ||
            Geocoder.log(:warn, "#{name} API error: invalid argument (#{doc['error']['message']}).")
        end
        return []
      end

      [doc]
    end

    def query_url_params(query)
      params = {}
      params[:languageCode] = query.language || configuration.language if query.language || configuration.language
      params[:regionCode] = query.options[:region] if query.options[:region]
      params
    end

    def default_field_mask
      # Must properly format fields according to Google Place API requirements
      [
        "id",
        "displayName.text",
        "formattedAddress",
        "location",
        "types",
        "websiteUri",
        "rating",
        "userRatingCount",
        "priceLevel",
        "businessStatus",
        "regularOpeningHours",
        "photos",
        "internationalPhoneNumber",
        "addressComponents"
      ].join(',')
    end

    def fields(query)
      if query.options.has_key?(:fields)
        return format_fields(query.options[:fields])
      end

      if configuration.has_key?(:fields)
        return format_fields(configuration[:fields])
      end

      nil
    end

    def format_fields(*fields)
      flattened = fields.flatten.compact
      return if flattened.empty?

      flattened.join(',')
    end

    def make_api_request(query)
      uri = URI.parse(query_url(query))

      Geocoder.log(:debug, "Making request to: #{uri}")

      response = http_client.start(uri.host, uri.port, use_ssl: use_ssl?) do |client|
        req = Net::HTTP::Get.new(uri.request_uri)
        req["X-Goog-Api-Key"] = configuration.api_key

        # Add the FieldMask header with proper formatting
        field_mask = query.options[:fields] || configuration[:fields] || default_field_mask
        req["X-Goog-FieldMask"] = field_mask

        Geocoder.log(:debug, "Using headers: #{req.to_hash.inspect}")

        client.request(req)
      end

      Geocoder.log(:debug, "Response code: #{response.code}")
      Geocoder.log(:debug, "Response body: #{response.body[0..200]}...")

      response
    end
  end
end
