@Chromatic = @Chromatic or {}

class Chromatic.App extends Backbone.Router

  initialize: (options) ->
    # Recent galleries
    @galleries = new Chromatic.GalleriesCollection(options.recent_galleries)

    # Current gallery
    if options.gallery
      @galleries.add(options.gallery, {merge: true}) # Merge in case gallery is also a recent gallery
      @galleries.get(options.gallery.slug).photos.add(options.gallery.photos) # Merge doesnt take care of photos

    # Initialize main views
    @home_view = new Chromatic.HomeView()
    @gallery_view = new Chromatic.GalleryView()
    @upload_view = new Chromatic.UploadView()
    @zoom_view = new Chromatic.ZoomView()

    Backbone.history.options = { pushState: true, hashChange: false }

  # Routes

  routes:
    "": "home"
    ":id": "gallery"
    ":id/:pos": "zoom"

  # Routes (directly called by URL or browser navigation)

  home: ->
    @home_view.up()
    @gallery_view.down()
    @zoom_view.down()
    @gallery = null

  gallery: (id) ->
    @gallery = @galleries.get(id)
    @home_view.down()
    @zoom_view.down()
    @gallery_view.up()

  zoom: (id, pos) ->
    @gallery = @galleries.get(id)
    @gallery_view.up()
    @zoom_view.up(false, @gallery.photos.at(pos-1))
    @home_view.down()

  # Transitions (triggered by user interaction)
  # Here we also have to update the URL ourselves

  fromHomeToGallery: (gallery) ->
    @gallery = gallery
    both_completed = _.after 2, => @gallery_view.up(true)
    @home_view.down true, both_completed
    @gallery.fetch { success: both_completed }
    Backbone.history.navigate(@gallery.id)

  fromHomeToCreateGallery: (callback) =>
    both_completed = _.after 2, =>
      Backbone.history.navigate(@gallery.id)
      @gallery_view.up(true)
      callback()
    @home_view.down true, both_completed
    @gallery = @galleries.create {own: true}, { success: both_completed }

  fromZoomToGallery: ->
    @zoom_view.down(true)
    @gallery_view.up() # gallery view is already up but we want to update page title and url
    Backbone.history.navigate(@gallery.id)

  fromGalleryToZoom: (photo) ->
    @zoom_view.up(true, photo)
    Backbone.history.navigate("#{@gallery.id}/#{@gallery.photos.indexOf(photo)+1}")