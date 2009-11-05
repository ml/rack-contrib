require 'test/spec'
require 'rack/mock'
require 'rack/contrib/superlogger'
require 'mocha'


context "Rack::Superlogger" do
  def test_response(logger, template)
    app = lambda { |env| 
      env["rack.superlogger.data"][:some_var] = "foobar"
      env["rack.superlogger.data"][:something_else] = "kiszonka"
      [200, { "Content-type" => "test/plain", "Content-length" => "3" }, ["foo"]] 
    }
    
    Rack::Superlogger.new(app, logger, template).call(Rack::MockRequest.env_for("?super=logger"))
  end
  
  specify "should substitute :keys in template with values from 'rack.logger'" do
    logger = mock("logger")
    logger.expects("info").with("foobar kiszonka").once
    
    test_response(logger, ':some_var :something_else')
  end
  
  specify "should substitute :content_length with Content-length from response" do
    logger = mock("logger")
    logger.expects("info").with("foobar kiszonka 3").once
    
    test_response(logger, ":some_var :something_else :content_length")
  end
  
  specify "should substitute :duration with the runtime of the application" do
    logger = mock("logger")
    logger.expects(:info).with("foobar kiszonka 0 ms")
    
    Time.expects(:now).twice.returns(123)
    
    test_response(logger, ':some_var :something_else :duration ms')
  end
  
  specify "should substitute :status with status" do
    logger = mock("logger")
    logger.expects(:info).with("foobar kiszonka 200")
    
    test_response(logger, ":some_var :something_else :status")
  end
  
  specify "should substitute a method name form Rack::Request with its result" do
    logger = mock("logger")
    logger.expects(:info).with("foobar kiszonka  super=logger") #double space - content_type should be nil
    
    test_response(logger, ":some_var :something_else :content_type :query_string")
  end
  
  specify 'logger should be accessible through env["rack.superlogger.raw_logger"]' do
    logger = mock("logger", :info => nil)
    
    app = lambda { |env| 
      env["rack.superlogger.raw_logger"].should.equal logger
      [200, { "Content-type" => "test/plain", "Content-length" => "0" }, [""] ] 
    }
    
    Rack::Superlogger.new(app, logger, "").call(Rack::MockRequest.env_for("/"))
  end
end