@Chromatic = @Chromatic or {}

class Chromatic.ZoomPhotoView extends Backbone.View

  initialize: (options) ->
    @render()
    $('#zoom').append(@el)

  render: ->
    @$photo_el = $('<div class="photo"></div>')
    @$background_el = $('<div class="background"></div>')

    if @model.isNew()
      @$photo_el.css('backgroundImage', "url(#{@model.get('big_data')})")
      @$background_el.css('backgroundImage', "url(#{@model.get('background_data')})")
    else
      big_img = new Image()
      big_img.onload = => @$photo_el.css('backgroundImage', "url(#{@model.bigURL()})")
      big_img.src = @model.bigURL()
      @$photo_el.css('backgroundImage', "url(#{@model.smallURL()})")
      @$background_el.css('backgroundImage', "url(#{@model.backgroundURL()})")

    @$el.append(@$photo_el, @$background_el)
    return this

  layout: (pos, offset=0, animated) =>
    container = $('#zoom')
    if container.width() / container.height() > @model.get("aspect_ratio")
      height = container.height()
      width  = container.height() * @model.get("aspect_ratio")
    else
      height = container.width() / @model.get("aspect_ratio")
      width  = container.width()

    @$photo_el.css
      height: height
      width:  width
      top:    (container.height() - height) / 2

    left = switch pos
      when 'previous' then -width-20+offset
      when 'current'  then (container.width()-width)/2+offset
      when 'next'     then container.width()+20+offset

    opacity = switch pos
      when 'current'  then 1-Math.abs(offset)/container.width()*2
      when 'previous' then 0+offset/container.width()*2
      when 'next'     then 0-offset/container.width()*2

    if animated
      @$photo_el.stop().animate({left: left}, 600, 'easeOutCirc')
      @$background_el.stop().animate({opacity: opacity}, 600, 'easeOutCirc')
    else
      @$photo_el.css('left', left)
      @$background_el.css('opacity', opacity)