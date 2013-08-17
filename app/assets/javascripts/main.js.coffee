# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  countries = gon.countries
  $('.country-selector input').autocomplete
    source: countries

  israel = $.get('assets/Israel.geo.json').done (data)->
    coords = data.features[0].geometry.coordinates[0]
    countryPath = new CountryPath coords
    countryCoords = countryPath.getCoordinates()
    console.log countryCoords

    countryView = new CountryView "#country1"
    countryView.showCountry countryCoords
      # c = new CountryView("#country1")
      # c.showCountry( countries.)

class CountryPath
  constructor: (coordinates)->
    coordinates = @rotateToOrigin coordinates
    mercatorCoords = @projectToMercator coordinates

    @coordinates = mercatorCoords

  getCoordinates: ->
    @coordinates

  rotateToOrigin: (coordinates)->
    average = _.reduce coordinates, (val, cur)->
      [val[0] + cur[0], val[1] + cur[1]]
    ,[0,0]

    average[0] /= coordinates.length
    average[1] /= coordinates.length

    _.map coordinates, (coord)->
      [coord[0] - average[0], coord[1] - average[1]]
      
  projectToMercator: (coordinates)->
    _.map coordinates, (coord)=>
      scale = 100
      [coord[0] * scale, @y2lat(coord[1]) * scale]

  y2lat: (a) -> 
    180/Math.PI * (2 * Math.atan(Math.exp(a*Math.PI/180)) - Math.PI/2)


class CountryView
  constructor: (canvasId)->
    @canvas = $(canvasId)[0]
    paper.setup @canvas
    @canvasWidth = 400
    @canvasHeight = 400

  showCountry: (countryCoords)->
    path = new paper.Path()
    path.strokeColor = 'black';

    correctedCoord = @projectToCanvas countryCoords[0]
    start = new paper.Point correctedCoord[0],correctedCoord[1]
    path.moveTo start

    _.each countryCoords, (coord)=>
      correctedCoord = @projectToCanvas coord
      path.lineTo correctedCoord
      path.moveTo coord

    paper.view.draw()

  projectToCanvas: (coord)->
    [coord[0] + @canvasWidth/2, @canvasHeight - coord[1] - @canvasHeight/2]

