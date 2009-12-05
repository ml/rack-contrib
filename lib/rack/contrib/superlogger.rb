module Rack
  class Superlogger
    module LogProcessor
      def self.[](type)
        case type
        when Class
          type
        when String, Symbol
          const_get type.to_s.capitalize
        else
          raise ArgumentError, "Unexpected type class #{type.class}"
        end
      end
      
      class Base
        attr_reader :logger
        
        def initialize(options)
          @options = options
        end
        
        def process(env)
          raise "Not implemented"
        end
      end

      class Templated < Base
        def initialize(options)
          @logger   = options.delete(:logger)   or raise ArgumentError, "You must specify a logger"
          @keys = []
          # extract keys to be substituted and replace them with %s for String#% sybstitution
          @template = options.delete(:template).gsub(/:\w+/) { |m| @keys << m[1..-1].to_sym; "%s" } or
            raise ArgumentError, "You must specify a template"
          @request_methods = @keys & Rack::Superlogger::REQUEST_METHODS
          super options
        end
        
        def process(env)
          if @request_methods.any?
            request = Rack::Request.new(env)
            @request_methods.each { |m| env["rack.superlogger.data"][m] = request.send(m) }
          end

          values = []
          @keys.each { |k| values << env["rack.superlogger.data"][k.to_sym] }
           
          @logger.info @template % values
        end
      end
    end
      
    REQUEST_METHODS = Rack::Request.public_instance_methods(false).
                        reject { |method_name| method_name =~ /[=\[]|content_length/ }.map { |m| m.to_sym }.freeze

    def initialize(app, options)
      @app, @processor = app, LogProcessor[options.delete(:type)].new(options)
    end
     
    def call(env)
      env["rack.superlogger.data"], env["rack.superlogger.raw_logger"] = {}, @processor.logger
            
      before = Time.now.to_f
      status, headers, body = @app.call(env)
      duration = ((Time.now.to_f - before.to_f) * 1000).floor 
      
      env["rack.superlogger.data"][:duration]       = duration.to_s
      env["rack.superlogger.data"][:status]         = status.to_s
      env["rack.superlogger.data"][:content_length] = headers["Content-length"]
      
      @processor.process env
      
      [status, headers, body]
    end
  end
end