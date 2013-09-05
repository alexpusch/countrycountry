#= require ./country_selector
#= require ./coordinates_unifier
#= require ./countries_view

$ ->
  countries = gon.countries

  countriesView = new CountriesView "#countries canvas",
    width: 400
    height: $("#countries canvas").height()
    margin: 20

  left_country = countries[_.random 0, countries.length]
  right_country = countries[_.random 0, countries.length]

  loadCountry = (country, side) ->
    $(".country-selector input[data-side=#{side}]").val(country)
    countryPromise = $.get("countries/#{country}.geo.json")
    countriesView.showCountry countryPromise, side 

  loadCountry left_country, "left"
  loadCountry right_country, "right"

  leftCountrySelector = new CountrySelector 
    countries: countries
    input: ".country-selector input[data-side=left]"
    onSelect: (country)-> loadCountry(country, "left")

  rightCountrySelector = new CountrySelector
    countries: countries
    input: ".country-selector input[data-side=right]"
    onSelect: (country)-> loadCountry(country, "right")