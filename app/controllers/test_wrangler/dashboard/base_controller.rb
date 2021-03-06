class TestWrangler::Dashboard::BaseController < TestWrangler::ApplicationController
  before_filter :ensure_html_request
  layout 'test_wrangler/dashboard'

  def bootstrap
    render text: "", layout: true
  end

  def ensure_html_request  
    return if request.format == :html
    render :nothing => true, :status => 406  
  end
  
end
