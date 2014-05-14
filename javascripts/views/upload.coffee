@Chromatic = @Chromatic or {}

class Chromatic.UploadView extends Backbone.View
  el: 'body'

  events:
    'dragenter': 'dragenter',
    'dragover': 'dragover',
    'dragleave #drop-zone': 'dragleave'
    'drop': 'drop',
    'change input[type=file]': 'handleChooserEvent'

  initialize: =>
    @$drop_zone_el = $('#drop-zone')
    @$drop_zone_el.hide()

  stopNativeDragDrop: (e) =>
    e.stopPropagation()
    e.preventDefault()

  handleChooserEvent: (e) =>
    return unless e.originalEvent.target.files.length
    setTimeout (=> @handleFiles(e.originalEvent.target.files)), 200 # setTimeout to work around Chrome's behaviour of skipping the fade-out-animation

  handleFiles: (files) =>
    @files = _.filter files, (file) -> file.type == 'image/jpeg'
    if Chromatic.app.gallery then @processNextFile() else Chromatic.app.fromHomeToCreateGallery @processNextFile

  dragenter: (e) =>
    @stopNativeDragDrop(e)
    return e.originalEvent.dataTransfer.dropEffect = 'none' if Chromatic.app.gallery and not Chromatic.app.gallery.isOwn()

    @$drop_zone_el.fadeIn()
    @$drop_zone_el.find('.caption').text if Chromatic.app.gallery then 'Drop photos to add them to this gallery' else 'Drop photos here to create a new gallery'

  # Not exactly sure why dragenter is not sufficient but Chrome insists on this
  dragover: (e) =>
    @stopNativeDragDrop(e)
    return e.originalEvent.dataTransfer.dropEffect = 'none' if Chromatic.app.gallery and not Chromatic.app.gallery.isOwn()

  dragleave: (e) =>
    @stopNativeDragDrop(e)
    @$drop_zone_el.fadeOut()

  drop: (e) =>
    @stopNativeDragDrop(e)
    @$drop_zone_el.hide()
    @handleFiles(e.originalEvent.dataTransfer.files) # WTF: files reference is empty when called in a fadeout callback

  uploadNextPhoto: =>
    return if Chromatic.app.gallery.photos.filter((p) -> p.isUploading()).length >= 3 # limit concurrent uploads
    if next = Chromatic.app.gallery.photos.find((p) -> p.isNew() && !p.isUploading()) then next.upload(@uploadNextPhoto)

  finishProcessingFile: =>
    @uploadNextPhoto()
    setTimeout @processNextFile.bind(this), 100

  processNextFile: =>
    return unless file = @files.shift()

    # file type check
    if file.type != "image/jpeg"
      # @failed_to_process_files.push([@current_file.name, "wrong_type"])
      return @finishProcessingFile()
    # file size checks
    if file.size < 100 * 1000
      # @failed_to_process_files.push([@current_file.name, "too_small"])
      return @finishProcessingFile()
    if file.size > 20 * 1000 * 1000
      # @failed_to_process_files.push([@current_file.name, "too_big"])
      return @finishProcessingFile()

    array_buffer_reader = new FileReader()
    array_buffer_reader.onload = (array_buffer_reader_event) =>
      result = array_buffer_reader_event.target.result

      # duplicate check
      fingerprint = SparkMD5.ArrayBuffer.hash(result)
      if fingerprint in Chromatic.app.gallery.photos.pluck("fingerprint")
        console.log "Photo with same fingerprint already present", fingerprint
        return @finishProcessingFile()

      # try to get shot_at from exif data (not so reliable)
      # fallback to file.lastModifiedDate
      try
        exif_reader = new ExifReader()
        exif_reader.load result
        exif_date = exif_reader.getTagDescription('DateTimeOriginal')
        shot_at = new Date(Date.parse("#{exif_date.split(" ")[0].replace(/:/g,'/')} #{exif_date.split(" ")[1]}"))
      shot_at = shot_at || file.lastModifiedDate

      data_url_reader = new FileReader()
      data_url_reader.onload = (data_url_reader_event) =>
        result = data_url_reader_event.target.result

        img = new Image()
        img.onload = =>
          small = resize(img, 800, 800)
          small.onload = =>
            background = blur(small, 180)
            big = resize(img, 2000, 2000)

            Chromatic.app.gallery.photos.add
              fingerprint: fingerprint,
              aspect_ratio: img.width / img.height,
              shot_at: shot_at,
              small_data: small.src,
              big_data: big.src,
              background_data: background.src

            @finishProcessingFile()

        img.src = result
      data_url_reader.readAsDataURL(file) # full image, used for preview and resize

    slice = file.slice || file.mozSlice || file.webkitSlice
    array_buffer_reader.readAsArrayBuffer(slice.call(file, 0, 131072)) # part image, used for exif data
