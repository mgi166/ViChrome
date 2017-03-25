this.vichrome ?= {}
g = this.vichrome

opt = {}
frameID = undefined

g.CommandExecuter::solveAlias = (alias) ->
        aliases = g.commandBox.getAlias()
        alias = aliases[alias]
        while alias?
            command = alias
            alias = aliases[alias]
        command

class MyCommandManager extends g.CommandManager
    constructor : (model, timeout)->
        super( model, timeout, false )

    execCommand : (com) ->
        executer = (new g.CommandExecuter).set( com.str ).parse()
        args = executer.getArgs()
        @model["req"+args[0]]?( args.slice(1) )


class g.CommandBox
    constructor : ->
        @inputListeners = []

    init : (@width, @align) ->
        @box   = $('div#vichromebox')
        @input = $('input#vichromeinput')
        @modeChar  = $( 'div#vichromemodechar' )
        @inputField = $('div#vichromefield' )
        @box.width( @width ).addClass('vichrome-commandbox'+@align)
        @input.width( @width - @modeChar.width() - 5 ).val("")
        @commandManager = new MyCommandManager(this, opt.commandWaitTimeOut)

        this

    addInputUpdateListener : (fn) ->
        @inputListeners.push( fn )
        this

    attachTo : () ->
        $(document.body).append( @box )
        this

    detachFrom : () ->
        if @candidateBox?
            @candidateBox.stop()
            @candidateBox.detachFrom()
        @input.val("")
        $(document).unbind()
        document.removeEventListener( "keydown" , @onKeyDown )
        this

    setFixedListener : (@fixedListener) -> this
    reqFocusNextCandidate : (args) -> @nextCandidate()
    reqFocusPrevCandidate : (args) -> @prevCandidate()
    reqEscape : (args) ->
        chrome.runtime.sendMessage({
            command      : "PassToFrame"
            innerCommand : "Escape"
        })
        @detachFrom()

    handleKey : (key) ->
        event.stopPropagation()
        if @value().length == 0 and ( key.code == "Backspace" or key.code == "Delete" )
            event.preventDefault()
            @reqEscape()
            return

        if key.code == "Enter"
            @fixedListener?( @value() )
            @detachFrom()
            return

        @commandManager.handleKey key, @keyMap

        return

    onKeyDown : (e) ->
        if g.KeyManager.isOnlyModifier( e.key, e.ctrlKey, e.shiftKey, e.altKey, e.metaKey )
            g.logger.d "getHandlableKey:only modefier"
            return

        code = g.KeyManager.getLocalKeyCode( e.key, e.ctrlKey, e.shiftKey, e.altKey, e.metaKey )
        unless code?
            g.logger.d "getHandlableKey:cant be handled"
            return

        key =
            code  : code
            shift : e.shiftKey
            ctrl  : e.ctrlKey
            alt   : e.altKey
            meta  : e.metaKey

        g.commandBox.handleKey( key )

    setKeyMap : (@keyMap) -> this
    setAlias  : (@aliases) -> this
    getAlias  : -> @aliases
    setIncremental : (@incremental) -> this

    show : (modeChar, input="") ->
        @input.attr( "value", input )
        @modeChar.html( modeChar )
        @bfInput = input

        @box.show()
        @inputField.show()

        $(document).keyup (e) =>
            val = @input.val()
            if @selectedCand == val then return

            if @bfInput != val and @isVisible()
                listener( val ) for listener in @inputListeners

            @bfInput = val

        document.addEventListener("keydown" , @onKeyDown, true)

        this

    hide : ->
        if @isVisible()
            @inputField.hide()
            @input.blur()
        this

    focus : ->
        @input.get(0)?.focus()
        this

    isVisible : -> @inputField.css( 'display' ) isnt 'none'

    value : (a) ->
        if a?
            @input.val(a)
        else
            return @input.val()

    setCandidateBox : (candBox) ->
        unless opt.enableCompletion then return this
        if @candidateBox?
            @candidateBox.stop()
            @candidateBox.detachFrom()

        @candidateBox = candBox.init(@width, @align)
        @candidateBox.setCommandBox this
        @candidateBox.attachTo(@view).show()
        this

    nextCandidate : ->
        if @candidateBox?
            focused = @candidateBox.focusNext()
            unless focused? then return this
            @selectedCand = focused.value ? focused.str
            @value( @selectedCand  )
        this

    prevCandidate : ->
        if @candidateBox?
            focused = @candidateBox?.focusPrev()
            unless focused? then return this
            @selectedCand = focused.value ? focused.str
            @value( @selectedCand  )
        this

    isValidKeySeq : (keySeq) ->
        if @keyMap[keySeq]
            return true
        else
            return false

    isValidKeySeqAvailable : (keySeq) ->
        # since escaping meta character for regexp is so complex that
        # using regexp to compare should cause bugs, using slice & comparison
        # with '==' may be a better & simple way.
        length     = keySeq.length

        for seq, command of @keyMap
            cmpStr = seq.slice( 0, length )
            pos    = cmpStr.indexOf("<", 0)
            if pos >= 0
                pos = seq.indexOf( ">", pos )
                if pos >= length
                    cmpStr = seq.slice( 0, pos+1 )
            if keySeq == cmpStr
                return true

        false

class g.CandidateBox
    itemHeight  : 22
    winColumns  : 20
    constructor : ->
        @items   = {}
        @sources = {}
        @selectedListeners = []
        @index    = 0
        @scrIndex = 0

    init : (@width, @align)->
        @box = $( '<div id="vichromecandbox" />' )
               .css( 'min-width', @width )
               .addClass( 'vichrome-candbox'+@align )
        this

    show : ->
        @box.show()
        this

    hide : ->
        @box.hide()
        this

    addItem : (id, item) ->
        @items[id].push(item)
        this

    getItemCnt : ->
        result = 0
        result += items.length for src,items of @items
        result


    addSource : (src) ->
        @sources[src.id] = src
        @items[src.id] = []
        src.addSrcUpdatedListener( (items) =>
            @items[src.id] = items
            @update(src.id)
        )
        this

    attachTo : () ->
        $(document.body).append( @box )
        this

    detachFrom : () ->
        @box.detach()
        this

    resetItem : ->
        @candidates = []
        this

    makeItemLine : (src, id, item) ->
        line = $("<div id=\"vichromecanditem\" source=\"#{src}\" num=\"#{id}\" />")
        text = $("<div id=\"vichromecandtext\" class=\"vichrome-candstr\" />").html( item.str )
        dscr = $("<div id=\"vichromecandtext\" class=\"vichrome-canddscr\" />").html( item.dscr )
        srcType = $("<div id=\"vichromecandtext\" class=\"vichrome-canddscr\" />").html( item.source )
        line.append( text ).append( srcType ).append( dscr )
        if item.value?
            line.attr("value", item.value)
        line

    update : (id)->
        $('#vichromecanditem'+"[source=#{id}]").remove()
        for item, i in @items[id]
            @box.append( @makeItemLine(id, i, item) )
        this

    getItem : (id, num) -> @items[id][num]

    scrollTo   : (@scrIndex) -> @box.get(0).scrollTop = @itemHeight * @scrIndex
    scrollDown : ->
        if @index >= @scrIndex + @winColumns
            @scrollTo( @scrIndex+1 )
        else if @index < @scrIndex
            @scrollTo( @index )
    scrollUp   : ->
        if @index >= @scrIndex + @winColumns
            @scrollTo(@getItemCnt() - @winColumns)
        else if @index < @scrIndex
            @scrollTo( @index )

    getFocusedValue : -> @focusedValue
    setFocusedValue : (@focusedValue) ->

    scrollTop  : -> @scrollTo( 0 )
    scrollBottom : ->
        @scrIndex = 0
        @box.get(0).scrollTop = 0

    removeFocus : ($focused) ->
        $focused.removeClass("vichrome-canditemfocused")
        $focused.children().removeClass("vichrome-canditemfocused")

    setFocus : ( $settee ) ->
        $settee.addClass("vichrome-canditemfocused")
        $settee.children().addClass("vichrome-canditemfocused")
        if (val = $settee.attr("value"))
            @setFocusedValue( val )

    focusNext : ->
        unless @getItemCnt() > 0 then return null
        $focused = $("#vichromecanditem.vichrome-canditemfocused")
        @removeFocus( $focused )
        $next = $focused.next()
        @index++
        if $next.attr("id") isnt "vichromecanditem"
            @index = 0
            $next = $("#vichromecanditem:first-child").first()

        @scrollDown()
        @setFocus( $next )
        @getItem( $next.attr("source"), parseInt( $next.attr("num") ) )

    focusPrev : ->
        unless @getItemCnt() > 0 then return null
        $focused = $("#vichromecanditem.vichrome-canditemfocused")
        @removeFocus( $focused )
        $next = $focused.prev()
        @index--
        if $next.attr("id") isnt "vichromecanditem"
            $next = $("#vichromecanditem:last-child").last()
            @index = @getItemCnt() - 1

        @scrollUp()
        @setFocus( $next )
        @getItem( $next.attr("source"), parseInt( $next.attr("num") ) )

    getFocused : ->
        $focused = $("#vichromecanditem.vichrome-canditemfocused")
        @getItem( $focused.attr("source"), parseInt( $focused.attr("num") ) )

    onInput : (word) ->
        if @stopped then return
        src.cbInputUpdated word for id, src of @sources
        return

    setCommandBox : (box) ->
        box.addInputUpdateListener( (word) => @onInput word )
        this

    stop : ->
        @stopped = true


class g.CandidateSource
    constructor : (@maxItems=5)->
        @updatedListeners = []
        @items = []

    requirePrefix : (@reqPrefix) -> this
    addSrcUpdatedListener : (listener) ->
        @updatedListeners.push( listener )
        this

    addItem : (item) ->
        @items.push( item ) if @items.length < @maxItems or @maxItems < 0
        this

    resetItem : ->
        @items = []
        this

    notifyUpdated : ->
        listener( @items ) for listener in @updatedListeners
        this

    cbInputUpdated : (word) ->
        if @timer? then clearTimeout @timer
        if @prefix? and word.charAt(1) == " " and word.charAt(0) != @prefix
            g.logger.d("different prefix:"+@prefix)
            @resetItem()
            @notifyUpdated()
            return

        if @reqPrefix and @prefix?
            if word.length<2 or word.charAt(1) != " " or word.charAt(0) != @prefix
                @resetItem()
                @notifyUpdated()
                return
            else
                word = word.slice(2)

        @timer = setTimeout( =>
            @timer = null
            @onInput?(word)
        , 150)

class g.CandSourceCommand extends g.CandidateSource
    id : "Command"
    constructor : (@maxItems=-1) ->
        super(@maxItems)
        chrome.runtime.sendMessage( {
            command : "GetCommandTable"
        }, (msg) => @commands = msg )

    onInput : (word) ->
        unless word.length > 0 then return
        unless @commands? then return
        @resetItem()
        word = word.toUpperCase()
        for com in @commands
            if com.toUpperCase().slice( 0, word.length ) == word
                @addItem(
                    str    : com
                    source : "Command"
                    dscr   : ""
                )

        @notifyUpdated()

class g.CandSourceAlias extends g.CandidateSource
    id : "Alias"
    constructor : (@maxItems=-1) ->
        super(@maxItems)
        chrome.runtime.sendMessage( {
            command : "GetAliases"
        }, (msg) => @aliases = msg )
    onInput : (word) ->
        unless word.length > 0 then return
        unless @aliases? then return
        @resetItem()
        word = word.toUpperCase()
        for alias, com of @aliases
            if alias.toUpperCase().slice( 0, word.length ) == word
                @addItem(
                    str    : alias
                    source : "Alias"
                    dscr   : com
                )

        @notifyUpdated()

class g.CandSourceHistory extends g.CandidateSource
    id : "WebHistory"
    prefix : "h"
    onInput : (word) ->
        unless word.length > 0 then return

        @resetItem()
        chrome.runtime.sendMessage( {
            command : "GetHistory"
            value   : word
        }, (items) =>
            unless items?
                @notifyUpdated()
                return

            for item in items
                str = if item.title then item.title else item.url
                @addItem(
                    str    : str
                    source : "History"
                    dscr   : item.url
                    value  : item.url
                )
            @notifyUpdated()
        )

class g.CandSourceBookmark extends g.CandidateSource
    id : "Bookmark"
    prefix : "b"
    onInput : (word) ->
        unless word.length > 0 then return

        @resetItem()
        chrome.runtime.sendMessage( {
            command : "GetBookmark"
            value   : word
        }, (nodes) =>
            unless nodes?
                @notifyUpdated()
                return

            for node in nodes
                @addItem(
                    str    : node.title
                    source : "Bookmark"
                    dscr   : node.url
                    value  : node.url
                )
            @notifyUpdated()
        )

class g.CandSourceSearchHist extends g.CandidateSource
    id : "SearchHistory"
    constructor : (@maxItems) ->
        super( @maxItems )
        chrome.runtime.sendMessage(
            command : "GetSearchHistory"
        , (msg) =>
            len = msg.value.length
            @history = msg.value.slice(len - @maxItems, len)
            @onInput("")
        )

    onInput : (word) ->
        unless @history? then return

        @resetItem()
        word = word.toUpperCase()
        for hist in @history
            if hist.toUpperCase().slice( 0, word.length ) == word
                @addItem(
                    str    : hist
                    source : "Search History"
                    dscr   : ""
                )

        @notifyUpdated()

class g.CandSourceGoogleSuggest extends g.CandidateSource
    id : "GoogleSuggest"
    prefix : "g"
    onInput : (word) ->
        unless word.length > 0 then return

        @resetItem()
        chrome.runtime.sendMessage( {
            command : "GetGoogleSuggest"
            value   : word
        }, (raws) =>
            unless raws?
                @notifyUpdated()
                return

            for raw in raws
                value = if @reqPrefix then "g "+raw else raw
                @addItem(
                    str    : raw
                    source : "Google Search"
                    dscr   : ""
                    value : value
                )
            @notifyUpdated()
        )

class g.CandSourceWebSuggest extends g.CandidateSource
    id : "WebSuggest"
    prefix : "w"
    onInput : (word) ->
        unless word.length > 0 then return

        @resetItem()
        if word.charAt(1) == " " and word.charAt(0) != "w"
            @notifyUpdated()
            return

        chrome.runtime.sendMessage( {
            command : "GetWebSuggest"
            value   : word
        }, (results) =>
            unless results?
                @notifyUpdated()
                return

            for res in results
                @addItem(
                    str    : res.titleNoFormatting
                    source : "Web"
                    dscr   : res.unescapedUrl
                    value  : res.url
                )
            @notifyUpdated()
        )

class g.CandSourceTabs extends g.CandidateSource
    id : "Tabs"
    constructor : (@maxItems=-1) ->
        chrome.runtime.sendMessage(
            command : "GetTabList"
        , (@tabs) => @onInput("") )
        super( @maxItems )

    onInput : (word) ->
        unless @tabs? then return

        @resetItem()
        word = word.toUpperCase()
        for tab in @tabs
            a = tab.title.toUpperCase()
            if tab.title.toUpperCase().indexOf( word ) >= 0
                @addItem(
                    str    : tab.title
                    source : ""
                    dscr   : "index:" + (tab.index+1)
                    value  : "" + (tab.index+1)
                )

        @notifyUpdated()

sender = 0

searchFixedListener = (word) ->
    chrome.runtime.sendMessage( {
        command      : "PassToFrame"
        innerCommand : "NotifySearchFixed"
        word         : word
        frameID      : sender
    })

searchUpdatedListener = (word) ->
    chrome.runtime.sendMessage( {
        command      : "PassToFrame"
        innerCommand : "NotifyInputUpdated"
        word         : word
        frameID      : sender
    })

commandFixedListener = (word) ->
    chrome.runtime.sendMessage( {
        command      : "TopFrame"
        innerCommand : "HideCommandFrame"
    })

    chrome.runtime.sendMessage( {
        command      : "PassToFrame"
        innerCommand : "ExecuteCommand"
        commandLine  : word
        frameID      : sender
    })

onRequest = (req) ->
    switch req.mode
        when "Command"
            sender = req.sender
            window.focus()

            candBox = (new g.CandidateBox)
            for src in req.sources
                reqPrefix = src.reqPrefix ? false
                obj = (new g[src.class](src.num))
                      .requirePrefix(reqPrefix)

                candBox.addSource( obj )

            g.commandBox.detachFrom() if g.commandBox?
            g.commandBox = (new g.CommandBox)
                          .init( opt.commandBoxWidth, opt.commandBoxAlign )
                          .attachTo()
                          .show( req.modeChar )
                          .focus()
                          .setKeyMap(req.keyMap)
                          .setAlias(req.aliases)
                          .setFixedListener(commandFixedListener)
                          .setCandidateBox( candBox )
        when "Search"
            sender = req.sender
            window.focus()

            candBox = (new g.CandidateBox)
            for src in req.sources
                reqPrefix = src.reqPrefix ? false
                obj = (new g[src.class](src.num))
                      .requirePrefix(reqPrefix)

                candBox.addSource( obj )

            g.commandBox.detachFrom() if g.commandBox?
            g.commandBox = (new g.CommandBox)
                          .init( opt.commandBoxWidth, opt.commandBoxAlign )
                          .attachTo()
                          .show( req.modeChar )
                          .focus()
                          .setIncremental(req.incSearch)
                          .setKeyMap(req.keyMap)
                          .setAlias(req.aliases)
                          .setFixedListener(searchFixedListener)
                          .setCandidateBox( candBox )

            if req.incSearch
                g.commandBox.addInputUpdateListener(searchUpdatedListener)

$(document).ready( ->
    g.logger.d "commandbox ready", this
    chrome.runtime.sendMessage( { command : "InitCommandFrame" }, (msg)->
        frameID = msg.frameID
        opt.enableCompletion = msg.enableCompletion
        opt.commandBoxWidth = msg.commandBoxWidth
        opt.commandBoxAlign = msg.commandBoxAlign
        opt.commandWaitTimeOut = msg.commandWaitTimeOut
    )

    chrome.runtime.onMessage.addListener( (req, sender, sendResponse) ->
        unless req.frameID? and req.frameID == frameID
            g.logger.d "onRequest: different frameID"
            sendResponse()
            return
        onRequest(req)
    )
)
