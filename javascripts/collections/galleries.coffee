@Chromatic = @Chromatic or {}

class Chromatic.GalleriesCollection extends Backbone.Collection
  model: Chromatic.Gallery
  url: '/recent'

  comparator: (obj) ->
    return new Date(obj.get("created_at"))*-1