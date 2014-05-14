@Chromatic = @Chromatic or {}

class Chromatic.Gallery extends Backbone.Model
  idAttribute: 'slug'

  url: =>
    if @isNew() then '/' else "/#{@id}.json"

  isOwn: =>
    !!@get('own')

  constructor: ->
    @photos = new Chromatic.PhotosCollection()
    Backbone.Model.apply(this, arguments)

  parse: (response) ->
    @photos.add(response.photos, {merge: true})
    delete response.photos
    return response