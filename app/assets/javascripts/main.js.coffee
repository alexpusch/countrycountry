# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  countries = gon.countries
  unifier = new CoordinatesUnifier
  countriesView = new CountriesView "#countries canvas",
    width: 400
    height: $("#countries canvas").height()
    margin: 20


  loadCountry = (country, side) ->
    $.get("assets/#{country}.geo.json").done (data)->
      window.data = data

      geoJson = unifier.unify data
      countriesView.showCountry geoJson, side

  loadCountry "Israel", "left"
  loadCountry "Germany", "right"
  # loadCountry "Germany", "right"
  $('.country-selector input[data-side=left]').val("Israel")
  $('.country-selector input[data-side=right]').val("Germany")


  $('.country-selector input').autocomplete
    source: countries
    select: (event, ui) ->
      side = $(event.target).data('side')
      country = ui.item.value
      loadCountry country, side

class CoordinatesUnifier
  unify: (geoJson)->  
    @translateToOrigin geoJson
    window.geoJson = geoJson
    @projectToMercator geoJson
    geoJson

  translateToOrigin: (geoJson)->
    delta = @findDeltaToOrigin geoJson
    @translateCoords geoJson.geometry.coordinates, delta

  findDeltaToOrigin: (geoJson)->
    coordinates = geoJson.geometry.coordinates
    coordinates = @flatten coordinates, []

    sum = _.reduce coordinates, (val, cur)->
      [val[0] + cur[0], val[1] + cur[1]]
    ,[0,0]

    delta = [-sum[0]/coordinates.length, -sum[1]/coordinates.length]

  translateCoords: (coordinates, delta)->
    @visitCoordinate coordinates, (coord)=>
      x: coord.x + delta[0]
      y: coord.y + delta[1]


  projectCoords: (coordinates)->
    @visitCoordinate coordinates, (coord)=>
      @projectToMercator coord

  visitCoordinate: (coordinates, action) ->
    _.each coordinates, (value)=>
      if(_.isArray(value) && !@isCoordinate(value))
        @visitCoordinate value, action
      else
        valueObj =
          {
            x: value[0]
            y: value[1]
          }

        returnObj = action valueObj

        value[0] = returnObj.x
        value[1] = returnObj.y

  flatten: (input, output)->
    _.each input, (value)=>
      if (_.isArray(value) && !@isCoordinate(value))
        @flatten(value, output)
      else
        output.push(value)

    output

  isCoordinate: (value)->
    _.isArray(value) && value.length == 2 && _.isNumber(value[0]) && _.isNumber(value[1])

  projectToMercator: (coord)->
    x: coord.x
    y: @y2lat(coord.y)

  y2lat: (a) -> 
    180/Math.PI * (2 * Math.atan(Math.exp(a*Math.PI/180)) - Math.PI/2)

  scale: (coordinates, scale)->
    _.map coordinates, (coord)->
      [coord[0]/unitScale, coord[1]/unitScale]



class CountriesView
  constructor: (canvasId, options = {})->
    @canvas = $(canvasId)[0]
    paper.setup @canvas

    $(@canvas).on 'mouseover', =>
      @animateIn = true

    $(@canvas).on 'mouseout', =>
      @animateOut = true

    paper.view.onFrame = (event) => @animate()
      
    @countryWidth = options.width
    @height = options.height
    @margin = options.margin
    @speed = 15

    @coords = 
      left: null
      right: null

    @paths = 
      left: new paper.CompoundPath()
      right: new paper.CompoundPath()

    window.paths = @paths

  showCountry: (geoJson, side)->
    @coords[side] = geoJson

    @render()

  render: ->
    unless @coords.left? && @coords.right?
      return

    leftPath = @createPathFromGeoJson @coords.left, @paths.left
    rightPath = @createPathFromGeoJson @coords.right, @paths.right

    @scaleToFit leftPath, rightPath
    @moveToPlace leftPath, rightPath

    paper.view.draw()

  createPathFromGeoJson: (countryGeoJson, path)->
    path.removeChildren()
    path.strokeColor = 'black';
    path.fillColor = 'red'

    switch countryGeoJson.geometry.type 
      when "Polygon" then @createSimplePath countryGeoJson.geometry.coordinates, path
      when "MultiPolygon" then @createMultiPath countryGeoJson.geometry.coordinates, path

  createSimplePath: (coordinates, path)->
    component = new paper.Path
    component = @createPath coordinates, component
    path.addChild component

    path

  createPath: (coordinates, path)->  
    coordinates = coordinates[0]

    correctedCoord = @projectToCanvas coordinates[0]
    start = new paper.Point correctedCoord[0],correctedCoord[1]
    path.moveTo start

    _.each coordinates, (coord)=>
      correctedCoord = @projectToCanvas coord
      path.lineTo correctedCoord
      path.moveTo coord

    path

  createMultiPath: (coordinates, path)->
    components = []
    _.each coordinates, (simplePolygon)=>
      component = new paper.Path
      component = @createPath simplePolygon, component
      components.push component

    path.addChildren components

    path

  moveToPlace: (left, right)->
    targetLeftCenter = new paper.Point(@margin + @countryWidth/2, @height/2)
    targetRightCenter = new paper.Point(3 * @margin + @countryWidth * 1.5, @height/2)

    leftDelta = targetLeftCenter.subtract left.bounds.center
    rightDelta = targetRightCenter.subtract right.bounds.center

    left.translate leftDelta
    right.translate rightDelta

  scaleToFit: (left, right)->
    leftBound = left.bounds
    rightBound = right.bounds

    maxSide = _.max [leftBound.width, leftBound.height, rightBound.width, rightBound.height]
    ratio = @height/maxSide 

    leftCenter = new paper.Point leftBound.center
    rightCenter = new paper.Point rightBound.center

    left.scale ratio, leftCenter
    right.scale ratio, rightCenter


  animate: ->
    if @animateIn || @animateOut
      if @animateIn
        target = @margin * 2 + @countryWidth
        speed = @speed
      if @animateOut
        target = (@margin + @countryWidth/2)
        speed = -@speed

      @paths.left.translate(new paper.Point(speed,0))
      @paths.right.translate(new paper.Point(-speed,0))

      if Math.abs(@paths.left.bounds.center.x - target) < @speed + 1
        @animateIn = false
        @animateOut = false

      paper.view.draw()
  projectToCanvas: (coord)->
    [coord[0], @height - coord[1]]

