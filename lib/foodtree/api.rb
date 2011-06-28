module Foodtree

  class API < Goliath::API
    include Goliath::Validation
    include Goliath::Rack::Validator

    ##
    # Perform some sane default routing for this api:
    #   
    #   index   - GET   /users
    #   show    - GET   /users/:id
    #   create  - POST  /users 
    #   update  - PUT   /users/:id
    #   delete  - DELETE /users/:id
    #
    #

    def route_request
      env.logger.debug "#{self.class} ROUTING - #{env[Goliath::Request::PATH_INFO]}"
      if has_path = ( env[Goliath::Request::PATH_INFO] =~ /^\/(\w+)(\/\w+)*/ )
        env.logger.debug "#{self.class} route_request:\t pathinfo = #{$1} extended = #{$2}"
        path_info = $1
        extended_path_info = $2
        has_path = true #it will be a number or nil - let's just make it a bool
      elsif params[:id]
        has_path = true
      end
      
      method = env[Goliath::Request::REQUEST_METHOD]
      action = case method
               when 'GET'
                 has_path ? 'show' : 'index'
               when 'POST'
                 has_path ? ( raise BadRequestError, "can't post to this resource" ) : 'create'
               when 'PUT'
                 !has_path ? ( raise BadRequestError, "no resource to PUT to" ) : 'update'
               when 'DELETE'
                 !has_path ? ( raise BadRequestError, "no resource to DELETE"  ) : 'delete'
               else
                 raise MethodNotAllowedError, "unknown request method"
               end
      env.logger.info "#{self.class} route_request:\t attempting to call #{action} action"
      if self.respond_to?(action, true)  #second param includes private methods
        env['params']['id'] = params[:id] || (path_info if has_path)
        self.send(action)
      else
        error_on MethodNotAllowedError, "#{action} not supported for this resource"
      end
    end 

    # help by logging the nature of the error.
    def error_on(exception, message)
      env.logger.debug "---BUILD ERROR RESPONSE #{self.class}---\t #{exception.inspect} with message #{message}"
      raise exception, message
    end
  end #class

end #module
