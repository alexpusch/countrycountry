#= require ./coordinates_unifier
#= require ./countries_view

$ ->
  countries = gon.countries
  unifier = new CoordinatesUnifier
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

  $('.country-selector input').autocomplete
    source: countries
    minLength: 0
    select: (event, ui) ->
      side = $(event.target).data('side')
      country = ui.item.value
      loadCountry country, side

    open: (event, ui)->
      $(event.target).css('border-bottom-left-radius', 0)
      $(event.target).css('border-bottom-right-radius', 0)

    close: (event, ui)->
      $(event.target).css('border-bottom-left-radius', "5px")
      $(event.target).css('border-bottom-right-radius', "5px")

  $('.country-selector input').focus (event, ui)->
    input = $(event.target)
    input.data('old-val', input.val())
    input.val ""
    input.autocomplete('search', '')

  $('.country-selector input').blur (event, ui)->
    input = $(event.target)

    if input.val() == '' && input.data('old-val')
      input.val input.data('old-val')

  $('.country-selector input').keypress (event)->
    if event.which == 13
      input = $(event.target)
      value = input.val()
      side = input.data "side"

      legalCountry = _.find countries, (country)->
        country.toLowerCase() == value.toLowerCase()

      if legalCountry?
        loadCountry legalCountry, side
        input.autocomplete("close")
        input.val(legalCountry)