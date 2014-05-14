@Chromatic = @Chromatic or {}

class Chromatic.HomeView extends Backbone.View
  el: '#home'

  initialize: =>
    @$el.hide()

  up: (animated, callback) =>
    return callback?() if @isUp()
    if animated then @$el.fadeIn 500, callback else @$el.show(); callback?()
    document.title = "Chromatic – Instantly create beautiful photo galleries"
    Chromatic.app.galleries.bind "remove", @refreshRecentGalleries
    @refreshRecentGalleries()

  down: (animated, callback) =>
    return callback?() unless @isUp()
    if animated then @$el.fadeOut 500, callback else @$el.hide(); callback?()

    Chromatic.app.galleries.unbind "remove", @refreshRecentGalleries

    Chromatic.app.galleries.each (gallery) =>
      gallery.recent_view.remove() if gallery.recent_view
      gallery.recent_view = null

  isUp: =>
    @$el.is(':visible')

  refreshRecentGalleries: =>
    $('#recent-galleries').empty()
    $('#recent-galleries').text("Your recent galleries: ") if Chromatic.app.galleries.any()
    _.each Chromatic.app.galleries.sort().first(5), (gallery) =>
      gallery.recent_view = new Chromatic.RecentGalleryView({model: gallery})
      $('#recent-galleries').append(gallery.recent_view.el)