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

end
