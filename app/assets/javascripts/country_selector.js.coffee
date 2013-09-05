class window.CountrySelector
  constructor: (options)->
    @countries = options.countries
    @selectCallback = options.onSelect
    @input = $(options.input)

    @setUpAutoComplete()
    @setUpFocusEvents()
    @setUpKeyboardEvents()

  setUpAutoComplete: ->
    @input.autocomplete
      source: @countries
      minLength: 0
      select: (event, ui)=>
        country = ui.item.value
        @triggerOnSelect country

      open: (event, ui)->
        $(event.target).css('border-bottom-left-radius', 0)
        $(event.target).css('border-bottom-right-radius', 0)

      close: (event, ui)->
        $(event.target).css('border-bottom-left-radius', "5px")
        $(event.target).css('border-bottom-right-radius', "5px")

  setUpFocusEvents: ->
    @input.focus (event, ui)=>
      input = $(event.target)
      @currentValue = input.val()
      input.val ""
      input.autocomplete('search', '')

    @input.blur (event, ui)=>
      input = $(event.target)

      if input.val() == '' && @currentValue
        input.val @currentValue

  setUpKeyboardEvents: ->
    @input.keypress (event)=>
      if event.which == 13
        input = $(event.target)
        value = input.val()

        legalCountry = _.find @countries, (country)->
          country.toLowerCase() == value.toLowerCase()

        if legalCountry?
          input.autocomplete("close")
          @triggerOnSelect legalCountry

  triggerOnSelect: (country)->
    @selectCallback(country)