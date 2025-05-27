require "geocoder/lookups/google"
require "geocoder/results/google_places_search"
require "json"

module Geocoder
  module Lookup
    # Updated to exclusively use Google Places API v1 (Search Text)
    class GooglePlacesSearch < Google
      def name
        "Google Places Search"
      end

      def required_api_key_parts
        ["key"]
      end

      def supported_protocols
        [:https]
      end

      private

      # v1 API returns results under the 'places' key
      def result_root_attr
        'places'
      end

      # v1 API endpoint for Search Text
      def base_query_url(query)
        "#{protocol}://places.googleapis.com/v1/places:searchText?"
      end

      # Logic to determine fields for the field mask
      def fields(query)
        if query.options.has_key?(:fields)
          return format_fields(query.options[:fields])
        end
        if configuration.has_key?(:fields)
          return format_fields(configuration[:fields])
        end
        default_fields
      end

      # v1 default fields
      def default_fields
        [
          "id", "displayName.text", "formattedAddress", "location", "types",
          "websiteUri", "rating", "userRatingCount", "priceLevel", "businessStatus",
          "regularOpeningHours", "photos"
        ].join(',')
      end

      # Helper to format fields
      def format_fields(*fields)
        flattened = fields.flatten.compact
        return nil if flattened.empty?
        flattened.join(',')
      end

      # Location bias helper
      def locationbias(query)
        query.options[:locationbias] || configuration[:locationbias]
      end

      # Define v1 URL parameters
      def query_url_params(query)
        params = {}
        params[:languageCode] = query.language || configuration.language if query.language || configuration.language
        params[:regionCode] = query.options[:region] if query.options[:region]
        params.merge!(query.options[:params] || {})
        params
      end

      # v1 POST request implementation
      def make_api_request(query)
        uri = URI.parse(query_url(query))

        http_client.start(uri.host, uri.port, use_ssl: use_ssl?) do |client|
          req = Net::HTTP::Post.new(uri.request_uri)
          req.body = request_body_json(query)
          req["Content-Type"] = "application/json"
          req["X-Goog-Api-Key"] = configuration.api_key
          client.request(req)
        end
      end

      # Builds the JSON request body for the v1 Search Text API
      def request_body_json(query)
        body = {
          textQuery: query.text
        }

        body[:locationBias] = locationbias(query) if locationbias(query)
        body[:languageCode] = query.language || configuration.language if query.language || configuration.language
        body[:regionCode] = query.options[:region] if query.options[:region]

        fields_mask = fields(query)
        if fields_mask
          body[:includedFields] = {
            paths: fields_mask.is_a?(Array) ? fields_mask : fields_mask.split(',')
          }
        end

        JSON.generate(body)
      end

      # Handle v1 API results
      def results(query)
        doc = fetch_data(query)
        return [] unless doc

        if doc['error']
          handle_error(doc)
          return []
        end

        doc[result_root_attr] || []
      end

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
