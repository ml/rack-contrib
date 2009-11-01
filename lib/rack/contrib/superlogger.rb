module Rack
  class Superlogger
    REQUEST_METHODS = Rack::Request.public_instance_methods(false).
                        reject { |method_name| method_name =~ /[=\[]|content_length/ }.freeze

    def initialize(app, logger, template)
      @app = app
      @logger = logger
      @template = template
    end

     
    def call(env)
      env["rack.superlogger"] = {}
      
      before = Time.now.to_f
      status, headers, body = @app.call(env)
      duration = ((Time.now.to_f - before.to_f) * 1000).floor 
      
      message = @template.dup
      request = Rack::Request.new(env)
      
      env["rack.superlogger"][:duration]       = duration.to_s             if message.include? ":duration"
      env["rack.superlogger"][:status]         = status.to_s               if message.include? ":status"
      env["rack.superlogger"][:content_length] = headers["Content-length"] if message.include? ":content_length"
      
      REQUEST_METHODS.each do |method_name|
        env["rack.superlogger"][method_name.to_sym] = request.send(method_name.to_sym) if message.include?(":#{method_name}")
      end
      
      env["rack.superlogger"].each do |k, v|
        message.gsub! ":#{k}", v.to_s
      end

      @logger.info message
      [status, headers, body]
    end
  end
end