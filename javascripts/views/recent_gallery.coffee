@Chromatic = @Chromatic or {}

class Chromatic.RecentGalleryView extends Backbone.View
  tagName: 'a'

  events:
    'click': 'open'

  initialize: =>
    @render()

  render: =>
    @$el.attr('href', @model.get('slug'))
    @$el.html(@model.get('slug'))

  open: (e) =>
    e.stopPropagation()
    Chromatic.app.fromHomeToGallery(@model)