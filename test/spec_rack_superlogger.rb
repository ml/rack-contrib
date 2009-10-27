require 'test/spec'
require 'rack/mock'
require 'rack/contrib/superlogger'
require 'mocha'


context "Rack::Superlogger" do
  def test_response(logger, template)
    app = lambda { |env| 
      env["rack.superlogger"][:some_var] = "foobar"
      env["rack.superlogger"][:something_else] = "kiszonka"
      [200, { "Content-type" => "test/plain", "Content-length" => "3" }, ["foo"]] 
    }
    
    Rack::Superlogger.new(app, logger, template).call(Rack::MockRequest.env_for("/"))
  end
  
  specify "should substitute :keys in template with values from 'rack.logger'" do
    logger = mock("logger")
    logger.expects("info").with("foobar kiszonka").once
    
    test_response(logger, ':some_var :something_else')
  end
  
  specify "should additionally substitute :duration with the runtime of the application" do
    logger = mock("logger")
    logger.expects(:info).with("foobar kiszonka 0 ms")
    
    Time.expects(:now).twice.returns(123)
    
    test_response(logger, ':some_var :something_else :duration ms')
  end
end