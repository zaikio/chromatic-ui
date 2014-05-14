@Chromatic = @Chromatic or {}

class Chromatic.GalleryView extends Backbone.View
  id: 'images'

  initialize: ->
    @$el.hide()
    $(document.body).append @$el

  up: (animated, callback) =>
    document.title = "Chromatic – #{Chromatic.app.gallery.get("slug")}"
    $(document.body).addClass("scroll")
    if @isUp()
      @layout()
      return callback?()
    else
      if animated then @$el.fadeIn 500, callback else @$el.show(); callback?()
      Chromatic.app.gallery.photos.bind "add", @photoWasAdded
      Chromatic.app.gallery.photos.bind "remove", @layout
      Chromatic.app.gallery.photos.each (photo) => @renderPhoto(photo)
      @layout()
      $(window).on 'resize', @debouncedLayout
      $(window).on 'scroll', @debouncedLazyLoad

  down: (animated, callback) =>
    return callback?() unless @isUp()
    if animated then @$el.fadeOut 500, callback else @$el.hide(); callback?()
    $(document.body).removeClass("scroll")
    $(window).off 'resize', @debouncedLayout
    $(window).off 'scroll', @debouncedLazyLoad

    if Chromatic.app.gallery
      Chromatic.app.gallery.photos.unbind "add", @photoWasAdded
      Chromatic.app.gallery.photos.unbind "remove", @layout
      Chromatic.app.gallery.photos.each (photo) =>
        photo.view.remove()
        photo.view = null

  isUp: =>
    @$el.is(':visible')

  photoWasAdded: (photo) =>
    @renderPhoto(photo)
    @layout()

  renderPhoto: (photo) =>
    photo.view ||= new Chromatic.GalleryPhotoView({model: photo})
    if (index = Chromatic.app.gallery.photos.indexOf(photo)) > 0
      Chromatic.app.gallery.photos.at(index-1).view.$el.after(photo.view.el)
    else
      @$el.prepend(photo.view.el)

  lazyLoad: =>
    threshold = 1000
    container = $(window)
    viewport_top = container.scrollTop() - threshold
    viewport_bottom = container.height() + container.scrollTop() + threshold
    Chromatic.app.gallery.photos.each (photo) =>
      if photo.view.top < viewport_bottom && photo.view.bottom > viewport_top then photo.view.load() else photo.view.unload()

  debouncedLazyLoad: =>
    $.debounce(100, => @lazyLoad())()

  layout: =>
    photos = Chromatic.app.gallery.photos # shorter handle
    return unless @isUp() and not photos.isEmpty()

    # (1) Find appropriate number of rows by dividing the sum of ideal photo widths by the width of the viewport
    viewport_width = @$el.width()
    ideal_height = parseInt($(window).height() / 2)
    summed_width = photos.reduce ((sum, p) -> sum += p.get('aspect_ratio') * ideal_height), 0
    rows = Math.round(summed_width / viewport_width)

    if rows < 1
      # (2a) Fallback to just standard size when just a few photos
      photos.each (photo) -> photo.view.resize parseInt(ideal_height * photo.get('aspect_ratio')), ideal_height
    else
      # (2b) Partition photos across rows using the aspect_ratio as weight
      weights = photos.map (p) -> parseInt(p.get('aspect_ratio') * 100) # weight must be an integer
      partition = linear_partition(weights, rows)

      # (3) Iterate through partition
      index = 0
      row_buffer = new Backbone.Collection
      _.each partition, (row) ->
        row_buffer.reset()
        _.each row, -> row_buffer.add(photos.at(index++))
        summed_ars = row_buffer.reduce ((sum, p) -> sum += p.get('aspect_ratio')), 0
        row_buffer.each (photo) -> photo.view.resize parseInt(viewport_width / summed_ars * photo.get('aspect_ratio')), parseInt(viewport_width / summed_ars)

    @lazyLoad()

  debouncedLayout: =>
    $.debounce(100, => @layout())()