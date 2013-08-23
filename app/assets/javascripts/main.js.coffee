# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  countries = gon.countries
  $('.country-selector input').autocomplete
    source: countries

  $.get('assets/Brazil.geo.json').done (data)->
    coords = data.features[0].geometry.coordinates[0]
    if coords.length == 1
      coords = coords[0]

    countryPath = new CountryPath coords
    countryCoords = countryPath.getCoordinates()
    console.log countryCoords

    countryView = new CountryView "#country1"
    countryView.showCountry countryCoords

  $.get('assets/South Africa.geo.json').done (data)->
    coords = data.features[0].geometry.coordinates[0]
    if coords.length == 1
      coords = coords[0]

    countryPath = new CountryPath coords
    countryCoords = countryPath.getCoordinates()
    console.log countryCoords

    countryView = new CountryView "#country2"
    countryView.showCountry countryCoords


class CountryPath
  constructor: (coordinates)->
    window.orig = coordinates
    coordinates = @rotateToOrigin coordinates
    window.rotated = coordinates
    coordinates = @scaleToUnit coordinates
    mercatorCoords = @projectToMercator coordinates
    window.mercator = mercatorCoords
    @coordinates = mercatorCoords

  getCoordinates: ->
    @coordinates

  rotateToOrigin: (coordinates)->
    sum = _.reduce coordinates, (val, cur)->
      [val[0] + cur[0], val[1] + cur[1]]
    ,[0,0]

    average = [sum[0]/coordinates.length, sum[1]/coordinates.length]

    _.map coordinates, (coord)->
      [coord[0] - average[0], coord[1] - average[1]]
      
  projectToMercator: (coordinates)->
    _.map coordinates, (coord)=>
      scale = 200
      [coord[0] * scale, @y2lat(coord[1]) * scale]

  y2lat: (a) -> 
    180/Math.PI * (2 * Math.atan(Math.exp(a*Math.PI/180)) - Math.PI/2)

  scaleToUnit: (coordinates)->
    window.max = @findAbsMax coordinates
    unitScale = Math.max max[0], max[1]

    _.map coordinates, (coord)->
      [coord[0]/unitScale, coord[1]/unitScale]

  findAbsMax: (coordinates)->
    firstAbs = [Math.abs(coordinates[0][0]), Math.abs(coordinates[1][0])]
    _.reduce coordinates, (max, cur)->
      curMax = _.clone max
      
      if max[0] < Math.abs cur[0]
        curMax[0] = Math.abs cur[0]
      
      if max[1] < Math.abs cur[1]
        curMax[1] = Math.abs cur[1]

      curMax
    ,firstAbs

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

