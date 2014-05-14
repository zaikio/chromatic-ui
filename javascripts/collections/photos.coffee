@Chromatic = @Chromatic or {}

class Chromatic.PhotosCollection extends Backbone.Collection
  model: Chromatic.Photo

  url: ->
    "/#{Chromatic.app.gallery.id}/photos"

  initialize: (models, options) ->
    # @base_url = options.url

  comparator: (obj) ->
    return new Date(obj.get("shot_at") || obj.get("created_at"))*1