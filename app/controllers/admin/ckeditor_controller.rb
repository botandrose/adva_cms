# Parent controller for the CKEditor engine's asset endpoints, so uploading and
# browsing assets requires an authenticated admin. Ckeditor is an isolated
# engine, so route helpers resolve against the engine; reach the host app's
# login route through main_app.
class Admin::CkeditorController < Admin::BaseController
  protected

    def redirect_to_login(notice = nil)
      redirect_to main_app.login_url(return_to: request.url), notice: notice
    end
end
