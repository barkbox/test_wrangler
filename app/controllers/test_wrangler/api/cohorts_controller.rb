class TestWrangler::Api::CohortsController < TestWrangler::Api::BaseController

  def index
    @cohorts = TestWrangler.cohort_names
    render json: {cohorts: @cohorts}
  end

  def show
    if TestWrangler.cohort_exists?(params[:cohort_name])
      @cohort = TestWrangler.cohort_json(params[:cohort_name])
      render json: {cohort: @cohort}
    else
      render nothing: true, status: 404
    end
  end

  def update
    if TestWrangler.cohort_exists?(params[:cohort_name])
      if TestWrangler.update_cohort(params[:cohort_name], params[:cohort])
        render json: {cohort: TestWrangler.cohort_json(params[:cohort_name])}
      else
        render nothing: true, status: 422
      end
    else
      render nothing: true, status: 404
    end
  end

  def create
    cohort_name = params[:cohort][:name]
    if TestWrangler.cohort_exists?(cohort_name)
      render nothing: true, status: 409
    else 
      criteria = params[:cohort][:criteria]
      priority = params[:cohort][:priority]
      @cohort = TestWrangler::Cohort.new(cohort_name, priority, criteria) rescue false
      saved = TestWrangler.save_cohort(@cohort) rescue false
      if @cohort && saved
        render json: {cohort: TestWrangler.cohort_json(@cohort)}
      else
        render nothing: true, status: 422
      end
    end
  end

  def destroy
    if TestWrangler.remove_cohort(params[:cohort_name])
      render nothing: true, status: 200
    else
      render nothing: true, status: 404
    end
  end
end
