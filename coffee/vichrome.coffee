this.vichrome ?= {}
g = this.vichrome

setTimeout( ->
  g.model.init()
  g.view    = new g.Surface
  g.handler = new g.EventHandler(g.model)

  Promise.resolve().then( ->
    new Promise (resolve, reject) ->
      chrome.runtime.sendMessage {
        command : "Init"
      }, (msg)-> resolve(g.handler.onInitEnabled(msg))
  ).then ->
    new Promise (resolve, reject) ->
       resolve(g.model.onDomReady())
, 100 )
