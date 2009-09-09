class Media::MediaDialog
  TYPES={
    "images"=>"Attēli",
    "files"=>"Datnes"
  }
  MEDIA_CLASSES={
    "images"=>Media::ImageFile,
    "files"=>Media::SimpleFile
  }
end
