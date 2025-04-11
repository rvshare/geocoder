require "geocoder/results/base"

module Geocoder::Result
  class GooglePlacesDetails < Base

    def coordinates
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
      @data['formattedAddress']
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

    def url
      @data['googleMapsUri']
    end

    def rating
      @data['rating']
    end

    def reviews
      @data['reviews'] || []
    end

    def photos
      @data['photos'] || []
    end

    def phone_number
      @data['internationalPhoneNumber']
    end

    def user_ratings_total
      @data['userRatingCount']
    end
    alias_method :rating_count, :user_ratings_total

    def business_status
      @data['businessStatus']
    end

    def price_level
      @data['priceLevel']
    end

    def open_hours
      if @data['regularOpeningHours'] && @data['regularOpeningHours']['periods']
        @data['regularOpeningHours']['periods']
      else
        []
      end
    end

    def open_now
      if @data['regularOpeningHours']
        @data.dig('regularOpeningHours', 'openNow')
      end
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

    def city
      address_component('locality', 'long_name')
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

      if value_type == 'short_name'
        component['shortText']
      else # long_name
        component['longText']
      end
    end
  end
end
