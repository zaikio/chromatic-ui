@S3Upload = {}

@S3Upload.upload = (data, s3_object_key, success, progress, error) ->
  xhr = new XMLHttpRequest

  xhr.upload.addEventListener "progress", progress
  xhr.addEventListener "load", (e) =>
    if e.target.status in [200..299] then success()
    else error()
  , false
  xhr.addEventListener "error", error

  form_data = new FormData
  form_data.append("key", s3_object_key)
  form_data.append("AWSAccessKeyId", @access_key)
  form_data.append("acl", @acl)
  form_data.append("policy", @policy)
  form_data.append("signature", @signature)
  form_data.append("Content-Type", 'image/jpeg')
  form_data.append("Cache-Control", 'max-age=94608000')
  form_data.append("file", data)
  xhr.open("POST", "http://#{@bucket}.s3.amazonaws.com", true)
  xhr.send(form_data)