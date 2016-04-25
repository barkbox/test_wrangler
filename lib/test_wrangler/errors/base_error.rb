module TestWrangler
  class BaseError < Exception
    attr_accessor :original_error

    def initialize(*args)
      original_error = args[0]

      if original_error && original_error.is_an?(Exception)
        super original_error.message
        self.original_error = original_error
        self.set_backtrace(original_error.backtrace)
      else
        super *args
      end

    end
  end
end
