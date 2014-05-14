@Chromatic = @Chromatic or {}

class Chromatic.GalleryPhotoView extends Backbone.View
  className: 'photo'

  events:
    'click .delete': 'delete'
    'click': 'zoom'

  initialize: (options) ->
    @model.bind "change:progress", @updateProgress
    @render()

  render: ->
    @$el.append "<div class=\"delete\"></div>" if Chromatic.app.gallery.isOwn()
    @$el.append "<div class=\"progress\" style=\"display:none\"><div><div></div></div></div>" if @model.isNew()

  load: =>
    return if @loaded
    url = if @model.isNew() then @model.get('small_data') else @model.smallURL()
    @$el.css('backgroundImage', "url(#{url})")
    @loaded = true

  unload: =>
    @$el.css('backgroundImage', "")
    @loaded = false

  updateProgress: (model, progress) =>
    if progress in [0..99]
      @$el.find('.progress').fadeIn().find('div div').css('width', "#{progress}%")
    else if progress == 100
      @$el.find('.progress').fadeOut().find('div div').css('width', "100%")

  delete: (e) =>
    e.stopPropagation()
    @remove()
    @model.destroy()

  zoom: =>
    Chromatic.app.fromGalleryToZoom(@model)

  resize: (width, height) ->
    @$el.css
      width: width - parseInt(@$el.css('marginLeft'))*2
      height: height - parseInt(@$el.css('marginTop'))*2
    @top = @$el.offset().top
    @bottom = @top + @$el.height()