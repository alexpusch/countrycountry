#= requrie ./geojson_path

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

    @setUpLoader()

    _.extend @paths.left, @pathStyle
    _.extend @paths.right, @pathStyle

    window.paths = @paths

  setUpLoader: ->
    @loader = new paper.PointText(new paper.Point(0,0))
    @loader.justification = 'center'
    @loader.fillColor = 'green'
    @loader.content = 'Loading...'
    @loader.fontSize = 28
   
    @loader.visible = false

  showCountry: (countryPromise, side)->
    @startLoading side
    @clearSide side

    countryPromise.done (data)=>
      @endLoading()

      unifier = new CoordinatesUnifier
      geoJson = unifier.unify data
      @coords[side] = geoJson

      @render()

  startLoading: (side)->
    @loader.position = @getSideCenter side
    @loader.visible = true
    

  endLoading: (side)->
    @loader.visible = false

  render: ->
    unless @coords.left? && @coords.right?
      return

    leftPath = @createPathFromGeoJson @coords.left, @paths.left
    rightPath = @createPathFromGeoJson @coords.right, @paths.right

    @scaleToFit leftPath, rightPath
    @moveToPlace leftPath, rightPath

    paper.view.draw()

  createPathFromGeoJson: (geoJson, path)->
    path = new GeoJsonPath path, (coord)=>
      [coord[0], @height - coord[1]]

    path.create geoJson

  moveToPlace: (left, right)->
    targetLeftCenter = @getLeftCenter()
    targetRightCenter = @getRightCenter()

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

  clearSide: (side)->
    @getPath(side).removeChildren()

  getPath: (side)->
    switch side
      when "left" then @paths.left
      when "right" then @paths.right   

  getSideCenter: (side)->
    switch side
      when "left" then @getLeftCenter()
      when "right" then @getRightCenter()

  getLeftCenter: ->
    new paper.Point(@margin + @countryWidth/2, @height/2)
    
  getRightCenter: ->
    new paper.Point(3 * @margin + @countryWidth * 1.5, @height/2)