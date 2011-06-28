
class Users < Foodtree::API
  
  class MissingMongoIDError < BadRequestError ; end
    
  def response(env)
    env.logger.info "\n\n ---- Users"
    resp = route_request
    resp
  end
    
  private 
 
  def index
    env.logger.debug "Users API:\t  ---- index"
    
    if env['params'].empty?
      env.logger.debug "Users API:\t get all users"
      users = User.all
      [200, {}, {:users => users}]
    elsif env['params'].include?('lat') && env['params'].include?('lng')
      location = [env['params'].delete('lat').to_f, env['params'].delete('lng').to_f]
      env.logger.debug "Users API:\t get nearby users for #{location}"
      nearby_users = User.near(location, 10)
      [200, {}, {:nearby_users => nearby_users}]
    else
      raise BadRequestError, "call without params for all users or with lat/lng pair for nearby users"
    end
  end
  
  def show
    env.logger.debug "Users API:\t  ---- show"
    user = do_get(verify_get_params)
    if user
      [200, {}, {:user => user}]
    else
      raise NotFoundError, 'User not found'
    end
  end
  
  def create #I wonder - should we just call these 'post' / 'get' etc?
     do_post( verify_post_params )
  end
  
  def update
    env.logger.debug "Users API:\t  ---- update"
    do_put(verify_put_params)
  end

  
  ## VERIFICATION METHODS
  
  def verify_get_params
    params = env['params'] || (raise BadRequestError, "no params!")
    env.logger.debug "Users API verify_get_params:\t Params are: #{params} and of type #{params.class}"
    params
  end
  
  def verify_post_params
    params = env['params']['user'] || (raise BadRequestError, "no params!")
    env.logger.debug "Users API verify_post_params:\t Params are: #{params} and of type #{params.class}"
        
    error_on(MissingS3keyError, "Missing 'id' - get your user id from your login") unless params['id']
    params['mongo_id'] = params.delete('id') #just so the external interface doesn't reveal the internal structure
    if avatar = params.delete('avatar_url')
      env.logger.debug "Users API verify_post_params:\t got avatar_url as parameter"
      #TODO - we need to check that the url is valid and exists
      params['avatar'] = $2
      params['avatar_host'] = $1
    end
    params
  end
  
  
  def verify_put_params
    env.logger.debug "Users API verify_put_params:\t put params are #{env['params'].inspect}"
    params = env['params']['user'] || (error_on BadRequestError, "no params!")
    params['id'] = env['params']['id']
    env.logger.debug "Users API verify_put_params:\t Params are: #{params} and of type #{params.class}"
    params
  end
  
  def do_get(params)
    user_id = params.delete('id')
    env.logger.debug "Users API do_get:\t user_id = #{user_id} and is of type #{user_id.class}"
    User.find_by_mongo_id(user_id)
  end
  
  #creat and save a new user       
  def do_post(params)
     env.logger.debug "creating user with params #{params.inspect}"
     @user = User.new(params)
     #save the user in the post process
     if save_user
       [200, {}, {:object => @user, :user_id => params['mongo_id']}]
     else
       raise BadRequestError, 'failed to save for some reason'
     end

  end
  
  def do_put(params)
    env.logger.debug "Users API do_put:\t creating user with params #{params.inspect}"
    user_id = params.delete('id')
    if @user = User.find_by_mongo_id(user_id)
      if params_s3_key = params['avatar']
        env.logger.info "Users API do_put:\t we've got an avatar to update"
        s3_key = params_s3_key.split('/')
        @user.avatar_host = s3_key[0..4].join('/') +'/'
        @user.avatar = s3_key.last
      end
      @user.attributes = params
      env.logger.debug "Users API do_put:\t user found: #{@user.inspect}, returning user object"
     if save_user
       [200, {}, {:object => @user, :user_id => params['mongo_id']}]
     else
       raise BadRequestError, 'failed to save for some reason'
     end
    else
      error_on NotFoundError, "user not found"
    end
  end
  
  def save_user
        begin 
          env.trace('before user save')
          env.logger.info("--- SAVE #{@user.class}:  #{@user.inspect}")
          if @user.save
          ## TODO - enforce uniqueness of S3 keys and return error on failure                
            env.logger.info "save successful"
            true
          else
            env.logger.info("auth post-process: \t-- WARNING: failed to save #{@user.class} - #{@user.inspect}\n #{@user.errors.messages}")
            return [400, json_headers(headers), JSON.generate({:error=> "#{@user.errors.messages}"})]
          end
        rescue
          env.logger.info("\nauth post-process: \t---\t ERROR: failed to save #{@user.class} - #{@user.inspect}\n #{$!.to_s}\n")
          return [500, json_headers(headers), JSON.generate({:error=> "save failed: " + $!.to_s})]
        end
  end 
end
