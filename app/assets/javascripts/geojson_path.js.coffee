class window.GeoJsonPath
  constructor: (path, @projectToCanvas)->
    @path = path
  
  create: (geoJson)->
    @createPathFromGeoJson geoJson, @path

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