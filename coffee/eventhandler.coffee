this.vichrome ?= {}
g = this.vichrome

class g.EventHandler
    constructor : (@model) ->

    onBlur : (e) ->
        g.logger.d "onBlur", e
        @model.onBlur( e.target )

    onKeyPress : (e) ->
        if g.model.isInSearchMode() or g.model.isInCommandMode()
            if !e.ctrlKey and !e.altKey and !e.metaKey
                event.stopPropagation()

    onKeyDown : (e) ->
        g.logger.d "onKeyDown", e
        msg = @getHandlableKey e
        if msg? then @model.handleKey msg

    # decide whether to post the key event and do some pre-post process
    # return true if the key event can be posted.
    getHandlableKey : (e) ->
        if g.KeyManager.isOnlyModifier( e.key, e.ctrlKey, e.shiftKey, e.altKey, e.metaKey )
            g.logger.d "getHandlableKey:only modifier"
            return undefined

        code = g.KeyManager.getLocalKeyCode( e.key, e.ctrlKey, e.shiftKey, e.altKey, e.metaKey )
        unless code?
            g.logger.d "getHandlableKey:cant be handled"
            return undefined

        if @model.prePostKeyEvent( code, e.ctrlKey, e.altKey, e.metaKey )
            return {
                code  : code
                shift : e.shiftKey
                ctrl  : e.ctrlKey
                alt   : e.altKey
                meta  : e.metaKey
            }
        else
            g.logger.d "prePostKeyEvent:key ignored by current mode"
            return

    onFocus : (e) ->
        g.logger.d "onFocus", e.target
        @model.onFocus e.target

    onMouseDown : (e) ->
        g.logger.d "onFocus", e
        @model.onMouseDown e

    addWindowListeners : ->
        document.addEventListener("keydown"   , ((e) => @onKeyDown(e))   , true)
        document.addEventListener("keypress"  , ((e) => @onKeyPress(e))  , true)
        document.addEventListener("focus"     , ((e) => @onFocus(e))     , true)
        document.addEventListener("blur"      , ((e) => @onBlur(e))      , true)
        document.addEventListener("mousedown" , ((e) => @onMouseDown(e)) , true)

    addExtListener : ->
        chrome.runtime.onMessage.addListener( (req, sender, sendResponse) =>
            g.logger.d "onRequest command: #{req.command}"
            if req.frameID? and req.frameID != g.model.frameID
                g.logger.d "onRequest: different frameID"
                return true

            switch req.command
                when "GetCommandTable"
                    commands = []
                    for com,method of g.CommandExecuter::commandTable
                        commands.push com
                    sendResponse commands
                when "GetAliases"
                    aliases = {}
                    for a,com of g.model.getAlias()
                        aliases[a] = com
                    sendResponse aliases
                when "OpenCommandBox"
                    g.model.openCommandBox( req )
                    sendResponse()
                when "ExecuteCommand"
                    g.model.curMode.reqExecuteCommand( req )
                    sendResponse()
                when "NotifyInputUpdated"
                    g.model.curMode.notifyInputUpdated( req )
                    sendResponse()
                when "NotifySearchFixed"
                    g.model.curMode.notifySearchFixed( req )
                    sendResponse()
                when "HideCommandFrame"
                    g.view.hideCommandFrame()
                    sendResponse()
                when "SetStatusLine"
                    g.view.setStatusLineText(req.text, req.timeout)
                    sendResponse()
                when "HideStatusLine"
                    g.view.hideStatusLine()
                    sendResponse()
                else
                    g.model.triggerCommand( "req#{req.command}", req.args, req.times, req.timesSpecified )
                    sendResponse()
            true
        )

    init : ->
        @addWindowListeners()
        @addExtListener()

    onInitEnabled : (msg) ->
        @init()
        @model.onInitEnabled( msg )

    onCommandResponse : (msg) ->
        unless msg? then return

        if msg.command == "Settings"
            @model.onSettings msg

        if msg.error? and msg.error == true
            g.logger.e "onCommandResponse: error occured!!!", msg
            g.model.curMode.reqEscape()
            g.view.setStatusLineText "Error:" + msg.errorMsg, 3000

