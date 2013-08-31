class window.CoordinatesUnifier
  unify: (geoJson)->  
    # @positivateAngels geoJson
    @translateToOrigin geoJson   
    @projectCoords geoJson

    window.geoJson = geoJson
    geoJson

  positivateAngels: (geoJson)->
    @visitCoordinate geoJson.geometry.coordinates, (coord)=>
      if coord.x < 0
        coord.x += 360

      if coord.y < 0
        coord.y += 360

      coord

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


  projectCoords: (geoJson)->
    @visitCoordinate geoJson.geometry.coordinates, (coord)=>
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