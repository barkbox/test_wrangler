class TestWrangler::Api::ExperimentsController < TestWrangler::Api::BaseController

  def index
    @experiments = TestWrangler.experiment_names
    render json: {experiments: @experiments}
  end
  
end
