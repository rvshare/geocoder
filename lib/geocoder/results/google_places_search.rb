require "geocoder/results/base"

module Geocoder::Result
  # Result class for Google Places API v1 (Search Text)
  class GooglePlacesSearch < Base
    def coordinates
      # Use v1 location format
      if @data.dig('location')
        [@data.dig('location', 'latitude'), @data.dig('location', 'longitude')]
      else
        []
      end
    end

    def address
      formatted_address
    end

    def formatted_address
      # Use v1 format
      @data['formattedAddress']
    end

    def name
      # Use v1 format
      @data.dig('displayName', 'text')
    end

    def place_id
      # Use v1 format
      @data['id']
    end

    def types
      # Use v1 format
      @data['types'] || []
    end

    def website
      # Use v1 format
      @data['websiteUri']
    end

    def rating
      # Use v1 format
      @data['rating']
    end

    def photos
      # Use v1 format
      @data['photos'] || []
    end

    def price_level
      # Use v1 format
      @data['priceLevel']
    end

    def rating_count
      # Use v1 format
      @data['userRatingCount']
    end

    def business_status
      # Use v1 format
      @data['businessStatus']
    end

    def open_hours
      # Use v1 format
      if @data['regularOpeningHours'] && @data['regularOpeningHours']['periods']
        @data['regularOpeningHours']['periods']
      else
        []
      end
    end

    def open_now
      # Use v1 format
      if @data['regularOpeningHours']
        @data.dig('regularOpeningHours', 'openNow')
      end
    end

    # Methods below are typically not available or reliable from Search Text
    # Keeping them empty or returning nil to avoid errors if called
    def city; nil; end
    def state; nil; end
    def state_code; nil; end
    def country; nil; end
    def country_code; nil; end
    def postal_code; nil; end
    def neighborhood; nil; end
    def street_number; nil; end
    def route; nil; end
    def street_address; nil; end
    def vicinity; formatted_address; end # Use formattedAddress as a fallback
    def attributions; nil; end # Attributions not typically in Search Text
    def viewport; nil; end # Viewport not typically in Search Text
    def phone_number; nil; end # Phone number not typically in Search Text
    def reviews; []; end # Reviews not typically in Search Text
    def short_formatted_address; formatted_address; end # Fallback
  end
end
