class TestWrangler::Api::CohortsController < TestWrangler::Api::BaseController

  def index
    @cohorts = TestWrangler.cohort_names
    render json: {cohorts: @cohorts}
  end

end
