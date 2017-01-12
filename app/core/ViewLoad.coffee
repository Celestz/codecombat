VIEW_LOAD_LOG = false
SHOW_NOTY = true

class ViewLoad
  @firstLoad: true
  constructor: (@view) ->
    @t0 = new Date()
    @firstLoad = ViewLoad.firstLoad
    ViewLoad.firstLoad = false

  setView: (@view) ->

  record: ->
    console.group('Recording view:', @view.id) if VIEW_LOAD_LOG
    views = [@view]
    networkPromises = []
    while views.length
      view = views.pop()
      views = views.concat(_.values(view.subviews))
      if not view.supermodel.finished()
        networkPromises.push(view.supermodel.finishLoading())
    console.log 'Network promises:', networkPromises.length if VIEW_LOAD_LOG

    Promise.all(networkPromises)
    .then =>
      imagePromises = []
      if VIEW_LOAD_LOG
        console.groupCollapsed('Images')
        console.groupCollapsed('Skipping')
        for img in @view.$('img:not(:visible)')
          console.log img.src
        console.groupEnd()
      for img in @view.$('img:visible')
        if not img.complete
          promise = new Promise((resolve) ->
            if img.complete
              resolve()
            else
              img.onload = resolve
              img.onerror = resolve
          )
          promise.imgSrc = img.src
          console.log img.src if VIEW_LOAD_LOG
          imagePromises.push(promise)

      console.groupEnd() if VIEW_LOAD_LOG
      return Promise.all(imagePromises)
    .then =>
      return console.groupEnd() if view.destroyed and VIEW_LOAD_LOG
      if @firstLoad
        m = "Loaded #{view.id} in: #{new Date() - window.performance.timing.fetchStart}ms (first load)"
      else
        m = "Loaded #{view.id} in: #{new Date() - @t0}ms"
      console.log m if VIEW_LOAD_LOG
      console.groupEnd() if VIEW_LOAD_LOG
      noty({text:m, type:'information', timeout: 1000, layout:'topCenter'}) if SHOW_NOTY
  
module.exports = ViewLoad
