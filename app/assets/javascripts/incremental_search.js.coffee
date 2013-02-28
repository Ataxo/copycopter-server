$.fn.incrementalSearch = (options) ->
  timeout = undefined
  matchAny = (object, fields, needle) ->
    index = 0
    if needle == "!!!NOTFILLED!!!"
      object["draft_content"] == ""
    else
      while index < fields.length
        return true  unless object[fields[index]].toLowerCase().indexOf(needle) is -1
        index++
      false

  matchQuery = (object, fields, needles) ->
    index = 0

    while index < needles.length
      return false  unless matchAny(object, fields, needles[index])
      index++
    true

  renderResults = (filter) =>
    list = $("<ul/>")
    resultCount = 0
    $.each options.items, ->
      if not filter or filter(this)
        list.append options.render(this)
        resultCount += 1

    @html ""
    @append list
    resultCount

  search = (query) =>
    timeout = null
    $.cookie('search_query', query);
    
    if query && query.length > 0
      $(options.clearQuery).show()
    else
      $(options.clearQuery).hide()

    $(options.noResults).hide()
    if query is ""
      $(options.viewAll).show()
      $(options.viewNotFilled).show()
      @html ""
    else
      $(options.viewAll).hide()
      $(options.viewNotFilled).hide()
      searchTerms = query.toLowerCase().split(" ")
      resultCount = renderResults((item) ->
        matchQuery item, options.search, searchTerms
      )
      $(options.noResults).show()  if resultCount is 0

  # serach by entering new character to query
  $(options.queryInput).keyup ->
    query = $(this).val()
    clearTimeout timeout  if timeout
    timeout = setTimeout(->
      search query
    , 250)


  #Clearing query by button
  $(options.clearQuery).click -> clearQuery()
    
  # clear serach by ESC
  $(options.queryInput).keyup (event)->
    if event.which == 27
      clearQuery()

  clearQuery = ->
    query = ""
    $(options.queryInput).val(query)
    $(options.queryInput).focus()
    clearTimeout timeout  if timeout
    timeout = setTimeout(->
      search query
    , 250)


  removeStart = ->
    $(options.queryInput).unbind "focus", removeStart
    $(options.blankSlate).slideUp()
    $(options.searchContainter).removeClass "start", "fast"

  $(options.queryInput).focus removeStart

  $(options.viewAll).click ->
    $(this).hide()
    $(options.viewNotFilled).show()
    $(options.viewAll).hide()
    renderResults()
    false
  $(options.viewNotFilled).click ->
    $(this).hide()
    $(options.viewAll).show()
    $(options.viewNotFilled).hide()
    renderResults((item) ->
      matchQuery item, options.search, ["!!!NOTFILLED!!!"]
    )
    false

  #On start set query input from remembered cookie
  $(options.clearQuery).hide()
  if $.cookie('search_query')
    $(options.queryInput).val($.cookie('search_query'))
    $(options.blankSlate).slideUp(1)
    removeStart()
    $(options.queryInput).focus()
    search $.cookie('search_query')

  return @
