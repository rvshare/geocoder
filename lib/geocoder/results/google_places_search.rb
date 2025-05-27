require "geocoder/results/google"

module Geocoder::Result
  # Result class for Google Places API v1 (Search Text)
  class GooglePlacesSearch < Google
    def coordinates
      if loc = @data.dig('location')
        [loc['latitude'], loc['longitude']]
      else
        []
      end
    end

    def latitude
      coordinates[0]
    end

    def longitude
      coordinates[1]
    end

    def address
      formatted_address
    end

    def formatted_address
      @data['formattedAddress'] || super
    end

    def name
      @data.dig('displayName', 'text')
    end

    def place_id
      @data['id']
    end

    def types
      @data['types'] || []
    end

    def website
      @data['websiteUri']
    end

    def rating
      @data['rating']
    end

    def photos
      @data['photos'] || []
    end

    def price_level
      @data['priceLevel']
    end

    def rating_count
      @data['userRatingCount']
    end

    def business_status
      @data['businessStatus']
    end

    def open_hours
      @data.dig('regularOpeningHours', 'periods') || []
    end

    def open_now
      @data.dig('regularOpeningHours', 'openNow')
    end

    def address_components; []; end
    def city; nil; end
    def state; nil; end
    def state_code; nil; end
    def country; nil; end
    def country_code; nil; end
    def postal_code; nil; end
    def route; nil; end
    def street_number; nil; end
    def street_address; nil; end
    def neighborhood; nil; end
    def vicinity; formatted_address; end
    def attributions; nil; end
    def viewport; nil; end
    def phone_number; nil; end
    def reviews; []; end
    def short_formatted_address; formatted_address; end
    def precision; nil; end
    def bounds; nil; end
  end
end
