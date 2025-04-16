require "geocoder/lookups/google"
require "geocoder/results/google_places_details"
require 'logger'

module Geocoder
  module Lookup
    class GooglePlacesDetails < Google
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

      # v1 API endpoint base
      def base_url
        "#{protocol}://places.googleapis.com/v1/places"
      end

      # Construct v1 path
      def base_query_url(query)
        place_id = query.text
        # Handle reverse geocoding coordinates - not supported by this lookup
        return "#{base_url}/unsupported_reverse_geocoding?" if place_id.is_a?(Array)

        encoded_place_id = URI.encode_www_form_component(place_id)
        "#{base_url}/#{encoded_place_id}?"
      end

      # result_root_attr is removed as v1 returns the result directly

      # Handle v1 results and errors
      def results(query)
        doc = fetch_data(query) # Directly fetch and parse
        return [] unless doc

        # Check for v1 errors
        if doc['error']
          handle_error(doc)
          return []
        end

        [doc] # Return the single result object in an array
      end

      # Logic to determine fields for the field mask (similar to master)
      def fields(query)
        if query.options.has_key?(:fields)
          return format_fields(query.options[:fields])
        end

        if configuration.has_key?(:fields)
          return format_fields(configuration[:fields])
        end

        default_field_mask # Use default if not specified
      end

      # Helper to format fields (same as master)
      def format_fields(*fields)
        flattened = fields.flatten.compact
        return nil if flattened.empty?
        flattened.join(',')
      end

      # Default fields for the v1 API field mask
      def default_field_mask
        # Define your default v1 fields here, e.g.:
        [
          "id", "displayName.text", "formattedAddress", "location", "types",
          "websiteUri", "rating", "userRatingCount", "priceLevel", "businessStatus",
          "regularOpeningHours", "photos", "internationalPhoneNumber",
          "addressComponents", "googleMapsUri"
        ].join(',')
      end

      # Define v1 URL parameters (replaces query_url_google_params)
      def query_url_params(query)
        params = {}
        params[:languageCode] = query.language || configuration.language if query.language || configuration.language
        params[:regionCode] = query.options[:region] if query.options[:region]
        # Allow custom params for tests or other needs
        params.merge!(query.options[:params] || {})
        params # Return only v1-specific and custom params
      end

      # Override make_api_request to add v1 headers
      def make_api_request(query)
        uri = URI.parse(query_url(query))

        http_client.start(uri.host, uri.port, use_ssl: use_ssl?) do |client|
          req = Net::HTTP::Get.new(uri.request_uri)
          req["X-Goog-Api-Key"] = configuration.api_key
          req["X-Goog-FieldMask"] = fields(query) # Use fields method for mask
          client.request(req)
        end
      end

      # --- Helper for error handling ---
      def handle_error(doc)
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
        else
          Geocoder.log(:warn, "#{name} API error: #{doc['error']['status']} (#{doc['error']['message']}).")
        end
      end

    end
  end
end
