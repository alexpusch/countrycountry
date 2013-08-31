#= require ./coordinates_unifier
#= require ./countries_view

$ ->
  countries = gon.countries
  unifier = new CoordinatesUnifier
  countriesView = new CountriesView "#countries canvas",
    width: 400
    height: $("#countries canvas").height()
    margin: 20


  loadCountry = (country, side) ->
    $.get("countries/#{country}.geo.json").done (data)->
      window.data = data

      geoJson = unifier.unify data
      countriesView.showCountry geoJson, side

  loadCountry "Japan", "left"
  loadCountry "Egypt", "right"

  $('.country-selector input[data-side=left]').val("Japan")
  $('.country-selector input[data-side=right]').val("Egypt")


  $('.country-selector input').autocomplete
    source: countries
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