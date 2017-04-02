this.vichrome ?= {}
g = this.vichrome

$(document).ready( ->
  setTimeout( ->
    g.model.init()
    g.view    = new g.Surface
    g.handler = new g.EventHandler(g.model)
    chrome.runtime.sendMessage {
        command : "Init"
    }, (msg)->g.handler.onInitEnabled(msg)
  , 100 )
  g.model.onDomReady()
)
