module Rack
  class Superlogger
    module LogProcessor
      class Base # may be async or sth
        def initialize(logger, template)
          @logger, @template = logger, template
        end
        
        def process(env)
          raise "Not implemented"
        end
      end

      class Simple < Base
        def process(env)
          request = Rack::Request.new(env)
          message = @template.dup

          Rack::Superlogger::REQUEST_METHODS.each do |method_name|
            env["rack.superlogger.data"][method_name.to_sym] = request.send(method_name.to_sym) if message.include?(":#{method_name}")
          end

          env["rack.superlogger.data"].each do |k, v|
            message.gsub! ":#{k}", v.to_s
          end

          @logger.info message
        end
      end
    end
      
    REQUEST_METHODS = Rack::Request.public_instance_methods(false).
                        reject { |method_name| method_name =~ /[=\[]|content_length/ }.freeze

    def initialize(app, logger, template)
      @app = app
      @logger = logger
      @processor = LogProcessor::Simple.new(@logger, template)
    end

     
    def call(env)
      env["rack.superlogger.data"], env["rack.superlogger.raw_logger"] = {}, @logger
            
      before = Time.now.to_f
      status, headers, body = @app.call(env)
      duration = ((Time.now.to_f - before.to_f) * 1000).floor 
      
      env["rack.superlogger.data"][:duration]       = duration.to_s
      env["rack.superlogger.data"][:status]         = status.to_s
      env["rack.superlogger.data"][:content_length] = headers["Content-length"]
      
      @processor.process(env)
      
      [status, headers, body]
    end
  end
end