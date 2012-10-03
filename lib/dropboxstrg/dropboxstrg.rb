require 'cloudstrg/cloudstrg'

class DropboxStrg < CloudStrg::CloudStorage
  require 'dropbox_sdk'
  
  APP_KEY = 'ebwn2abt7mznz56'
  APP_SECRET = 'g03si51tws05re3'
  ACCESS_TYPE = :app_folder 

  mattr_accessor :session, :client, :user, :redirect_path
  @session = nil
  @client = nil
  @username = nil
  @redirect_path = nil

  def initialize params
    @session = DropboxSession.new(APP_KEY, APP_SECRET)
  end

  def config params
    @redirect_path = params[:redirect]
    @username = params[:username]
    user = Cloudstrguser.find_by_name(@username)

    session = params[:session]
    
    if session[:dropbox_rkey] and session[:dropbox_rsecret]
      begin
        @session.set_request_token(session[:dropbox_rkey], session[:dropbox_rsecret])
        @session.get_access_token()
        user.dropbox_akey = @session.access_token.key
        user.dropbox_asecret = @session.access_token.secret
        session[:dropbox_rkey] = nil
        session[:dropbox_rsecret] = nil
        user.save()
      rescue DropboxAuthError
        @session = DropboxSession.new(APP_KEY, APP_SECRET)
        user.dropbox_akey = nil
        user.dropbox_asecret = nil
        session[:dropbox_rkey] = nil
        session[:dropbox_rsecret] = nil
        user.save()
        params[:session] = session
        return config params
      end
    else
      @session.get_request_token()    

      if user.dropbox_akey and user.dropbox_asecret
        @session.set_access_token(user.dropbox_akey, user.dropbox_asecret)
      else
        session[:dropbox_rkey] = @session.request_token.key
        session[:dropbox_rsecret] = @session.request_token.secret
        return session, @session.get_authorize_url(callback=@redirect_path)
      end
    end
    @client = DropboxClient.new(@session, ACCESS_TYPE)
    return session, false
  end

  def create_file params
    if not @client
      return false
    end
    filename = params[:filename]
    filename += ".json" if not filename.include? ".json"
    @client.put_file("/#{@username}/#{filename}", params[:file_content])
    true
  end

  def create_folder params
    if not @client
      return false
    end
    @client.file_create_folder("/#{@username}")
  end

  def get_file params
    if not @client
      return false
    end
    filename = params[:fileid]
    filename += ".json" if not filename.include? ".json"
    return filename, filename, @client.get_file("/#{@username}/#{filename}")
  end

  def update_file params
    if not @client
      return false
    end
    filename = params[:fileid]
    filename += ".json" if not filename.include? ".json"
    @client.put_file("/#{@username}/#{filename}", params[:file_content], overwrite=true)
    true
  end

  def remove_file params
    if not @client
      return false
    end
    filename = params[:fileid]
    filename += ".json" if not filename.include? ".json"
    @client.file_delete("/#{@username}/#{filename}")
  end

  def list_files
    if not @client
      return false
    end
    data = @client.metadata("/#{@username}/")
    lines = []
    data["contents"].each do |line|
      lines.append([line["path"].split("/")[-1],line["path"].split("/")[-1]]) if line["path"].include? ".json"
    end
    return lines
  end

end
