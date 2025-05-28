require "geocoder/results/google"

module Geocoder::Result
  class GooglePlacesDetails < Google

    def coordinates
      if loc = @data.dig('location')
        [loc['latitude'], loc['longitude']]
      else
        []
      end
    end

    def formatted_address
      @data['formattedAddress'] || super
    end

    def address
      formatted_address
    end

    def name
      @data.dig('displayName', 'text')
    end

    def place_id
      @data['id']
    end

    def types
      @data["types"] || []
    end

    def website
      @data["websiteUri"]
    end

    def url
      @data["googleMapsUri"]
    end

    def rating
      @data["rating"]
    end

    def reviews
      @data["reviews"] || []
    end

    def photos
      @data['photos'] || []
    end

    def phone_number
      @data["internationalPhoneNumber"]
    end

    def user_ratings_total
      @data["userRatingCount"]
    end
    alias_method :rating_count, :user_ratings_total

    def business_status
      @data["businessStatus"]
    end

    def price_level
      @data["priceLevel"]
    end

    def open_hours
      @data.dig('regularOpeningHours', 'periods') || []
    end

    def open_now
      @data.dig('regularOpeningHours', 'openNow')
    end

    def permanently_closed?
      business_status == 'CLOSED_PERMANENTLY'
    end

    def address_components
      @data['addressComponents'] || []
    end

    def address_components_of_type(type)
      return [] if address_components.empty?

      address_components.select do |c|
        types = c['types'] || []
        types.any?{ |t| type.to_s === t }
      end
    end

    def locality
      address_component('locality', 'long_name')
    end

    def sublocality
      address_component('sublocality', 'long_name')
    end

    def city
      return locality unless locality.blank?

      sublocality
    end

    def state
      address_component('administrative_area_level_1', 'long_name')
    end

    def state_code
      address_component('administrative_area_level_1', 'short_name')
    end

    def country
      address_component('country', 'long_name')
    end

    def country_code
      address_component('country', 'short_name')
    end

    def postal_code
      address_component('postal_code', 'long_name')
    end

    def neighborhood
      address_component('neighborhood', 'long_name')
    end

    def street_number
      address_component('street_number', 'short_name')
    end

    def route
      address_component('route', 'long_name')
    end

    def street_address
      [street_number, route].compact.join(' ')
    end

    private

    def address_component(component_type, value_type)
      components = address_components_of_type(component_type)
      return nil if components.empty?

      component = components.first
      key = (value_type == 'short_name') ? 'shortText' : 'longText'
      component[key]
    end
  end
end
