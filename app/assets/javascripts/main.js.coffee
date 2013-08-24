# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  countries = gon.countries
  $('.country-selector input').autocomplete
    source: countries

  unifier = new CoordinatesUnifier
  countriesView = new CountriesView "#countries canvas",
    width: 400
    height: $("#countries canvas").height()
    margin: 20


  $.get('assets/Israel.geo.json').done (data)->
    coords = data.features[0].geometry.coordinates[0]
    if coords.length == 1
      coords = coords[0]

    countryCoords = unifier.unify coords
    console.log countryCoords

    countriesView.showCountry countryCoords, "left"

  $.get('assets/Germany.geo.json').done (data)->
    coords = data.features[0].geometry.coordinates[0]
    if coords.length == 1
      coords = coords[0]

    countryCoords = unifier.unify coords
    console.log countryCoords

    countriesView.showCountry countryCoords, "right"

class CoordinatesUnifier
  unify: (coordinates)->
    rotated = @rotateToOrigin coordinates
    mercator = @projectToMercator rotated
    mercator

  rotateToOrigin: (coordinates)->
    sum = _.reduce coordinates, (val, cur)->
      [val[0] + cur[0], val[1] + cur[1]]
    ,[0,0]

    average = [sum[0]/coordinates.length, sum[1]/coordinates.length]

    _.map coordinates, (coord)->
      [coord[0] - average[0], coord[1] - average[1]]
      
  projectToMercator: (coordinates)->
    _.map coordinates, (coord)=>
      scale = 100
      [coord[0] * scale, @y2lat(coord[1]) * scale]

  y2lat: (a) -> 
    180/Math.PI * (2 * Math.atan(Math.exp(a*Math.PI/180)) - Math.PI/2)

  scale: (coordinates, scale)->
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

class CountriesView
  constructor: (canvasId, options = {})->
    @canvas = $(canvasId)[0]
    @countryWidth = options.width
    @height = options.height
    @margin = options.margin

    @paths = 
      left: null
      right: null

    paper.setup @canvas

  showCountry: (countryCoords, side)->
    path = @createPath countryCoords
    @paths[side] = path
    window.paths = @paths

    @render()

  createPath: (countryCoords)->
    path = new paper.Path()
    path.strokeColor = 'black';

    correctedCoord = @projectToCanvas countryCoords[0]
    start = new paper.Point correctedCoord[0],correctedCoord[1]
    path.moveTo start

    _.each countryCoords, (coord)=>
      correctedCoord = @projectToCanvas coord
      path.lineTo correctedCoord
      path.moveTo coord

    path

  render: ->
    unless @paths.left? && @paths.right?
      return

    @scaleToFit()
    @moveToPlace()

    paper.view.draw()

  moveToPlace: ->
    targetLeftCenter = new paper.Point(@margin + @countryWidth/2, @height/2)
    targetRightCenter = new paper.Point(3 * @margin + @countryWidth * 1.5, @height/2)

    leftDelta = targetLeftCenter.subtract @paths.left.bounds.center
    rightDelta = targetRightCenter.subtract @paths.right.bounds.center

    @paths.left.translate leftDelta
    @paths.right.translate rightDelta

  scaleToFit: ->
    leftBound = @paths.left.bounds
    rightBound = @paths.right.bounds

    maxSide = _.max [leftBound.width, leftBound.height, rightBound.width, rightBound.height]
    ratio = @height/maxSide 

    leftCenter = new paper.Point leftBound.center
    rightCenter = new paper.Point rightBound.center

    @paths.left.scale ratio, leftCenter
    @paths.right.scale ratio, rightCenter

  projectToCanvas: (coord)->
    [coord[0], @height - coord[1]]

