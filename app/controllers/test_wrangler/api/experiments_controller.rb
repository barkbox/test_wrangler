class TestWrangler::Api::ExperimentsController < TestWrangler::Api::BaseController

  def index
    @experiments = TestWrangler.experiment_names
    render json: {experiments: @experiments}
  end

  def show
    if ( @experiment = TestWrangler.experiment_json(params[:experiment_name]) )
      @cohorts = TestWrangler.cohort_names
      render json: { experiment: @experiment, cohorts: @cohorts }
    else
      render nothing: true, status: :not_found
    end
  end
  
end
