@Chromatic = @Chromatic or {}
UPLOAD_PROGRESS_STEPS = [0, 55, 70, 85, 100]

class Chromatic.Photo extends Backbone.Model

  toJSON: ->
    _.pick(@attributes, 's3_object_key', 'aspect_ratio', 'shot_at', 'fingerprint');

  upload: (callback) =>
    return if @isUploading() or @hasUploadFailed()
    @set('s3_object_key', guid())

    @set('progress', UPLOAD_PROGRESS_STEPS[0])
    blob = dataURLtoBlob(@get('big_data'))
    S3Upload.upload blob, "#{@get('s3_object_key')}/big.jpg", =>

      @set('progress', UPLOAD_PROGRESS_STEPS[1])
      blob = dataURLtoBlob(@get('small_data'))
      S3Upload.upload blob, "#{@get('s3_object_key')}/small.jpg", =>

        @set('progress', UPLOAD_PROGRESS_STEPS[2])
        blob = dataURLtoBlob(@get('background_data'))
        S3Upload.upload blob, "#{@get('s3_object_key')}/background.jpg", =>

          @set('progress', UPLOAD_PROGRESS_STEPS[3])
          @save null,
            success: =>
              @set('progress', UPLOAD_PROGRESS_STEPS[4])
              callback()
            error: =>  @set('progress', -1) # failed

        ,
        (e) => @set('progress', parseInt(e.loaded / e.total * (UPLOAD_PROGRESS_STEPS[3]-UPLOAD_PROGRESS_STEPS[2])) + UPLOAD_PROGRESS_STEPS[2]),
        (e) => @set('progress', -1) # failed

      ,
      (e) => @set('progress', parseInt(e.loaded / e.total * (UPLOAD_PROGRESS_STEPS[2]-UPLOAD_PROGRESS_STEPS[1])) + UPLOAD_PROGRESS_STEPS[1]),
      (e) => @set('progress', -1) # failed

    ,
    (e) => @set('progress', parseInt(e.loaded / e.total * UPLOAD_PROGRESS_STEPS[1])),
    (e) => @set('progress', -1) # failed

  isUploading: =>
    @get('progress') in [0..99]

  hasUploadFailed: =>
    @get('progress') == -1

  rootURL: =>
    # Use one of 4 domains to speed up parallel image downloading
    # Always use the same domain for the same photo to hit browser cache
    "http://img#{parseInt(@get("fingerprint")[0],16)%4}.chromatic.io/#{@get("s3_object_key")}"

  smallURL: =>
    "#{@rootURL()}/small.jpg"

  bigURL: =>
    "#{@rootURL()}/big.jpg"

  backgroundURL: =>
    "#{@rootURL()}/background.jpg"