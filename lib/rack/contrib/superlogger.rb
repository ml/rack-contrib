module Rack
  class Superlogger
    
    def initialize(app, logger, template)
      @app = app
      @logger = logger
      @template = template
    end
    
    def call(env)
      env["rack.superlogger"] = {}
      before = Time.now.to_f

      status, headers, body = @app.call(env)
      
      duration = (Time.now.to_f - before.to_f).floor 
      message = @template.dup
      
      env["rack.superlogger"].each do |k, v|
        message.gsub! ":#{k}", v
      end

      if message =~ /:duration/
        message.gsub! ":duration", duration.to_s
      end
        
      
      @logger.info message
      [status, headers, body]
    end
  end
end