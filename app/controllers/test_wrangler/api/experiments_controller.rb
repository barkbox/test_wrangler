class TestWrangler::Api::ExperimentsController < TestWrangler::Api::BaseController

  def index
    @experiments = TestWrangler.experiment_names
    render json: {experiments: @experiments}
  end

  def show
    if (@experiment = TestWrangler.experiment_json(params[:experiment_name]))
      @cohorts = TestWrangler.cohort_names
      render json: { experiment: @experiment, cohorts: @cohorts }
    else
      render nothing: true, status: :not_found
    end
  end

  def create
    experiment_name = params[:experiment][:name]
    if TestWrangler::experiment_exists?(experiment_name)
      render nothing: true, status: 409
    else 
      variants = params[:experiment][:variants]
      @experiment = TestWrangler::Experiment.new(experiment_name, variants) rescue false
      if @experiment && TestWrangler::save_experiment(@experiment)
        render json: {experiment: TestWrangler::experiment_json(@experiment)}
      else
        render nothing: true, status: 422
      end
    end
  end

  def update
    if TestWrangler.experiment_exists?(params[:experiment_name])
      updates = params[:experiment]
      if TestWrangler.update_experiment(params[:experiment_name], updates)
        render json: {experiment: TestWrangler.experiment_json(params[:experiment_name])}
      else
        render nothing: true, status: 422
      end
    else
      render nothing: true, status: :not_found
    end
  end
  
end
