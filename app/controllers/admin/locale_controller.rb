class Admin::LocaleController < ApplicationController
  allow Admin::Role.admin
  menu_actions :system=>{:index=>"index"}
  def index
    Mime::Type.register "application/zip", :zip
    merger = Lolita::LocaleMerger.new
    respond_to do |format|
      format.html do
        @locale_status_report = merger.status_report_cached
        render :layout => (request.xhr? ? false : "cms/default")
      end
      format.zip do
        merger.create_locale_zip unless File.exists? merger.locales_zip
        send_file merger.locales_zip, :filename => "locales.zip"
      end
    end
  end
end