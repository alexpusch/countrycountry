require 'country_provider.rb'

class MainController < ApplicationController
  def index
    country_provider = CountiesProvider.new "app/assets/countries"
    gon.countries = country_provider.get_countries_list
  end
end
