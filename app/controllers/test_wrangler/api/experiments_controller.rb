class TestWrangler::Api::ExperimentsController < TestWrangler::Api::BaseController

  def index
    @experiments = TestWrangler.experiment_names.map{|e| TestWrangler.experiment_json(e)}
    render json: {experiments: @experiments}
  end

  def show
    if (@experiment = TestWrangler.experiment_json(params[:experiment_name]))
      render json: { experiment: @experiment }
    else
      render nothing: true, status: :not_found
    end
  end

  def create
    experiment_name = create_experiment_params[:name]
    if TestWrangler.experiment_exists?(experiment_name)
      render nothing: true, status: 409
    else 
      variants = create_experiment_params[:variants]
      @experiment = TestWrangler::Experiment.new(experiment_name, variants) rescue false
      if @experiment && TestWrangler.save_experiment(@experiment)
        render json: {experiment: TestWrangler.experiment_json(@experiment)}
      else
        render nothing: true, status: 422
      end
    end
  end

  def update
    if TestWrangler.update_experiment(params[:experiment_name], update_experiment_params)
      render json: {experiment: TestWrangler.experiment_json(params[:experiment_name])}
    else
      render nothing: true, status: :not_found
    end
  end

  def destroy
    if TestWrangler.remove_experiment(params[:experiment_name])
      render json: {}, status: 200
    else
      render nothing: true, status: :not_found
    end
  end

private
  
  def update_experiment_params
    slice = params[:experiment].slice(:state, :cohorts) rescue {}
    slice[:cohorts] = [] if slice.has_key?(:cohorts) && slice[:cohorts].nil?
    slice
  end

  def create_experiment_params
    slice = params[:experiment].slice(:name, :variants) rescue {}
    slice[:variant] = [] if slice.has_key?(:variant) && slice[:variant].nil?
    slice
  end

end
