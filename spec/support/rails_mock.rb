require 'pathname'

class FakeRails
  def self.root
      @root ||= Pathname.new('/srv/my_app')
  end
end
