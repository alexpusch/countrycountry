class window.CountriesView
  constructor: (canvasId, options = {})->
    @canvas = $(canvasId)[0]
    paper.setup @canvas

    $(@canvas).on 'mouseover', =>
      @animateIn = true

    $(@canvas).on 'mouseout', =>
      @animateOut = true

    @pathStyle = 
      strokeColor : 'black';
      fillColor : 'green'
      strokeWidth : 2
      opacity : 0.5

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

    _.extend @paths.left, @pathStyle
    _.extend @paths.right, @pathStyle

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

    switch countryGeoJson.geometry.type 
      when "Polygon" then @createSimplePath countryGeoJson.geometry.coordinates, path
      when "MultiPolygon" then @createMultiPath countryGeoJson.geometry.coordinates, path

  createSimplePath: (coordinates, path)->
    component = new paper.Path
    component = @createPath coordinates, component
    path.addChild component

    path

  createMultiPath: (coordinates, path)->
    components = []
    _.each coordinates, (simplePolygon)=>
      # A simple polygon wight have holes in it, so we need
      # to iterate over its components
      _.each simplePolygon, (subPolygon)=>
        component = new paper.Path
        component = @createPath [subPolygon], component
        components.push component

    path.addChildren components

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