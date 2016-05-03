module TestWrangler
  module Helper
    BLANK_SELECTION = HashWithIndifferentAccess.new({cohort: nil, experiment: nil, variant: nil})
    
    def test_wrangler_selection
      return @test_wrangler_selection if defined? @test_wrangler_selection
      if cookies['test_wrangler']
        @test_wrangler_selection = HashWithIndifferentAccess.new(JSON.parse(Rack::Utils.unescape(cookies['test_wrangler']))) rescue BLANK_SELECTION
      else
        @test_wrangler_selection = BLANK_SELECTION
      end
    end

    def complete_experiment
      selection = test_wrangler_selection
      cookies.delete('test_wrangler')
      selection
    end

  end
end
