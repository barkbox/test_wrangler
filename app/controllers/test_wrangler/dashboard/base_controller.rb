class TestWrangler::Dashboard::BaseController < TestWrangler::ApplicationController
  before_action :ensure_html_request
  layout 'test_wrangler/dashboard'

  def bootstrap
    render nothing: true, layout: true
  end

  def ensure_html_request  
    return if request.format == :html
    render :nothing => true, :status => 406  
  end
  
end