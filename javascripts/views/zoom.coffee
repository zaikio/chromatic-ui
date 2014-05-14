@Chromatic = @Chromatic or {}

# Extend jquery with easeOut transition (loading jquery UI would be overkill)
$.extend $.easing,
  easeOutCirc: (x, t, b, c, d) ->
    return c * Math.sqrt(1 - (t=t/d-1)*t) + b

jQuery.event.special.swipe.settings.sensitivity = 100

class Chromatic.ZoomView extends Backbone.View
  id: 'zoom'

  events:
    'swipeup':       'close'
    'swiperight':    'showPrevious'
    'swipeleft':     'showNext'
    'swipecanceled': 'cancel'
    'click .left':   'showPrevious'
    'click .right':  'showNext'
    'click':         'close'
    'move':          'move'
    'mousemove':     'showArrows'
    'mouseenter':    'showArrows'
    'mouseleave':    'hideArrows'

  initialize: =>
    @$el.hide()
    $(document.body).append @render().$el

  render: =>
    @$el.html("<div class=\"arrow left\"></div><div class=\"arrow right\"></div>")
    @delegateEvents()
    return this

  down: (animated, callback) =>
    return callback?() unless @isUp()
    $(document.body).css('overflowY', 'auto')
    @$el.fadeOut (if animated then 500 else 1), =>
      @previous_zoom_photo_view.remove()
      @current_zoom_photo_view.remove()
      @next_zoom_photo_view.remove()
      @previous_zoom_photo_view = null
      @current_zoom_photo_view  = null
      @next_zoom_photo_view     = null
      key.unbind 'esc';key.unbind 'enter';key.unbind 'up';key.unbind 'left';key.unbind 'j';key.unbind 'right';key.unbind 'k'; # unbind doesnt support multiple keys
      $(window).off 'resize orientationchange', @debouncedLayout

  up: (animated, photo, callback) =>
    if @isUp()
      return callback() if @current == photo
    else
      if animated then @$el.fadeIn(500) else @$el.show(); callback?()
      $(document.body).css('overflowY', 'hidden') # prevent translucent scrollbars
      key 'esc, enter, up', @close
      key 'left, k',        $.throttle(500, @showPrevious)
      key 'right, j',       $.throttle(500, @showNext)
      $(window).on 'resize orientationchange', @debouncedLayout
      @hideArrows(false)

    photos    = Chromatic.app.gallery.photos
    @previous_zoom_photo_view.remove() if @previous_zoom_photo_view
    @current_zoom_photo_view.remove()  if @current_zoom_photo_view
    @next_zoom_photo_view.remove()     if @next_zoom_photo_view
    previous  = photos.at(photos.indexOf(photo) - 1) || photos.last()
    @current  = photo
    next      = photos.at(photos.indexOf(photo) + 1) || photos.first()
    @previous_zoom_photo_view = new Chromatic.ZoomPhotoView({model: previous})
    @current_zoom_photo_view  = new Chromatic.ZoomPhotoView({model: @current})
    @next_zoom_photo_view     = new Chromatic.ZoomPhotoView({model: next})
    @layout()
    @updatePageTitle()

  isUp: => @$el.is(':visible')

  layout: (offset=0, animated) =>
    return unless @isUp()
    @current_zoom_photo_view.layout('current', offset, animated)
    @previous_zoom_photo_view.layout('previous', offset, animated)
    @next_zoom_photo_view.layout('next', offset, animated)

  debouncedLayout: =>
    $.debounce(100, => @layout())()

  move: (e) => @layout(e.distX, false)

  cancel: (e) => @layout(0, true)

  close: =>
    clearTimeout(@arrows_timer)
    Chromatic.app.fromZoomToGallery()

  showNext: (e) =>
    e.preventDefault() if e
    e.stopPropagation() if e
    if e.type == "keydown" then @hideArrows() else @showArrows()
    photos    = Chromatic.app.gallery.photos
    @previous_zoom_photo_view.remove()
    @previous_zoom_photo_view = null
    @previous_zoom_photo_view = @current_zoom_photo_view
    @current_zoom_photo_view  = @next_zoom_photo_view
    @current  = photos.at(photos.indexOf(@current) + 1) || photos.first()
    next      = photos.at(photos.indexOf(@current) + 1) || photos.first()
    @next_zoom_photo_view = new Chromatic.ZoomPhotoView({model: next})
    @previous_zoom_photo_view.layout('previous', 0, true)
    @current_zoom_photo_view.layout('current', 0, true)
    @next_zoom_photo_view.layout('next', 0, false)
    @updatePageTitle()
    @updateRoute()

  showPrevious: (e) =>
    e.preventDefault() if e
    e.stopPropagation() if e
    if e.type == "keydown" then @hideArrows() else @showArrows()
    photos    = Chromatic.app.gallery.photos
    @next_zoom_photo_view.remove()
    @next_zoom_photo_view = null
    @next_zoom_photo_view = @current_zoom_photo_view
    @current_zoom_photo_view = @previous_zoom_photo_view
    @current  = photos.at(photos.indexOf(@current) - 1) || photos.last()
    previous  = photos.at(photos.indexOf(@current) - 1) || photos.last()
    @previous_zoom_photo_view = new Chromatic.ZoomPhotoView({model: previous})
    @next_zoom_photo_view.layout('next', 0, true)
    @current_zoom_photo_view.layout('current', 0, true)
    @previous_zoom_photo_view.layout('previous', 0, false)
    @updatePageTitle()
    @updateRoute()

  showArrows: =>
    @$el.find(".arrow").stop().animate({opacity: 1}, 200)
    clearTimeout(@arrows_timer)
    @arrows_timer = window.setTimeout((=> @hideArrows(true)), 3000)

  hideArrows: (animated) =>
    @$el.find(".arrow").animate({opacity: 0.01}, animated ? 1000 : 0) # still clickable

  updatePageTitle: =>
    gallery = Chromatic.app.gallery
    document.title = "#{gallery.photos.indexOf(@current) + 1}/#{gallery.photos.length} – Chromatic – #{gallery.get("slug")}"

  updateRoute: =>
    gallery = Chromatic.app.gallery
    Backbone.history.navigate("#{gallery.id}/#{gallery.photos.indexOf(@current)+1}")