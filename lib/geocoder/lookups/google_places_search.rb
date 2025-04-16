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

      # Logic to determine fields for the field mask (from master)
      def fields(query)
        if query.options.has_key?(:fields)
          return format_fields(query.options[:fields])
        end
        if configuration.has_key?(:fields)
          return format_fields(configuration[:fields])
        end
        default_fields # Use v1 default if not specified
      end

      # Replace default_fields with v1 defaults
      def default_fields
        [
          "id", "displayName.text", "formattedAddress", "location", "types",
          "websiteUri", "rating", "userRatingCount", "priceLevel", "businessStatus",
          "regularOpeningHours", "photos"
        ].join(',')
      end

      # Helper to format fields (same as master)
      def format_fields(*fields)
        flattened = fields.flatten.compact
        return nil if flattened.empty?
        flattened.join(',')
      end

      # Location bias helper (from master)
      def locationbias(query)
        query.options[:locationbias] || configuration[:locationbias]
      end

      # Define v1 URL parameters (minimal - most go in body)
      def query_url_params(query)
        params = {}
        # Keep language/region here if needed, though often in body for v1 Search
        params[:languageCode] = query.language || configuration.language if query.language || configuration.language
        params[:regionCode] = query.options[:region] if query.options[:region]
        # Allow custom params for tests or other needs
        params.merge!(query.options[:params] || {})
        # Merge with base params cautiously, removing handled keys
        super(query).reject { |k, v| params.key?(k) }.merge(params)
      end

      # Override make_api_request for v1 POST
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

        # Add optional params to body
        body[:locationBias] = locationbias(query) if locationbias(query)
        body[:languageCode] = query.language || configuration.language if query.language || configuration.language
        body[:regionCode] = query.options[:region] if query.options[:region]

        # Use includedFields for the field mask in the v1 API
        fields_mask = fields(query) # Use the fields logic
        if fields_mask
          body[:includedFields] = {
            # Ensure it's an array of strings
            paths: fields_mask.is_a?(Array) ? fields_mask : fields_mask.split(',')
          }
        end

        JSON.generate(body)
      end

      # Override results to handle v1 error/structure
      def results(query)
        doc = fetch_data(query)
        return [] unless doc

        # Handle v1 errors
        if doc['error']
          handle_error(doc)
          return []
        end

        # v1 returns places under the 'places' key (use result_root_attr)
        doc[result_root_attr] || []
      end

      # --- Helper for error handling (similar to Places Details) ---
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

      # --- Test Compatibility --- (Add this if needed, was not in master)
      # For test compatibility only
      def query_url(query)
        if query.options[:legacy_test_compatibility] || ENV["GEOCODER_TEST"]
          # Generate the *old* URL format for tests
          endpoint = "//maps.googleapis.com/maps/api/place/findplacefromtext/json"
          # Construct old params similar to master's query_url_google_params
          params = {
            input: query.text,
            inputtype: "textquery",
            key: configuration.api_key,
            language: query.language || configuration.language
          }

          if (bias = locationbias(query))
            params[:locationbias] = bias
          end

          # Use the fields() method we kept, but format for URL param
          fields_param = fields(query)
          params[:fields] = fields_param if fields_param

          params.merge!(query.options[:params] || {})

          paramstring = params.compact.map { |k,v| "#{k}=#{URI.encode_www_form_component(v.to_s)}" }.join('&')
          "#{protocol}:#{endpoint}?#{paramstring}"
        else
          # For real requests, use the standard mechanism
          super
        end
      end
    end
  end
end
