class TestWrangler::Api::BaseController < TestWrangler::ApplicationController
  before_action :ensure_json_request  

  def ensure_json_request  
    return if request.format == :json
    render :nothing => true, :status => 406  
  end
  
end
