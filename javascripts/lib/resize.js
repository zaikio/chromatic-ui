function resize(img, max_width, max_height){
  var c = document.createElement('canvas');
  var context = c.getContext('2d');

  var width = img.width;
  var height = img.height;

  if (width > height) {
    if (width > max_width) {
      height *= max_width / width;
      width = max_width;
    }
  } else {
    if (height > max_height) {
      width *= max_height / height;
      height = max_height;
    }
  }

  width = parseInt(width)
  height = parseInt(height)

  c.width = width;
  c.height = height;
  context.drawImage(img, 0, 0, width, height);

  var resized_img = new Image(width, height)
  resized_img.src = c.toDataURL("image/jpeg", 0.70);
  return resized_img;
}