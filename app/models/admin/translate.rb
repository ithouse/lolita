class Admin::Translate < Cms::Base
  self.abstract_class = true

  def self.js_translations
    {
      :too_much=>:"javascript.too much",
      :wait_dialog_header=>:"javascript.wait dialog header",
      :confirm=>:"actions.confirm",
      :cancel=>:"actions.cancel",
      :error=>:"simple words.error",
      :error_dialog_text=>:"javascript.error dialog text",
      :saving=>:"javascript.media.saving",
      :changes_saved=>:"javascript.media.changes saved",
      :media_error=>:"javascript.media.error",
      :picture_attributes=>:"image file.dialog.header"
    }
  end
end
