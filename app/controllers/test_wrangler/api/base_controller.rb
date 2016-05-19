class TestWrangler::Api::BaseController < TestWrangler::ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :ensure_json_request  

  def ensure_json_request  
    return if request.format == :json
    render :nothing => true, :status => 406  
  end
  
end
