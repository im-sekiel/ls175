require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

# Helper methods
def not_include_file?(file_path)
  @files.select do |file|
    file == file_path
  end.empty?
end

def render_markdown(file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render("#{file}")
end

def load_file_content(file_path)
  content = File.read(file_path)
  case File.extname(file_path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yaml", __FILE__)
  else
    File.expand_path("../users.yaml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

before do
  # Gives us the absolute path of the current file
  @files = Dir.glob(File.join(data_path, "*"))
end

helpers do
  # Removes file's path
  def remove_path(path)
    File.basename(path)
  end

  def render_markdown(file)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render("#{file}")
  end
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user

  unless user_signed_in?
    session[:error] = "You must be signed in to do that."
    redirect '/'
  end
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

# ROUTES

get '/' do
  erb :index, layout: :layout
end

get '/new' do
  require_signed_in_user

  erb :create
end

get '/:file' do
  file_path = File.join(data_path, params[:file])

  if not_include_file?(file_path)
    session[:error] = "#{params[:file]} does not exist."
    redirect '/' 
  else
    load_file_content(file_path)
  end
end

post '/:file/edit' do
  require_signed_in_user

  file_path = File.join(data_path, params[:file])

  @file = params[:file]
  @content = File.read(file_path)

  erb :edit, layout: :layout
end

post '/new' do
  require_signed_in_user

  file = params[:create].to_s

  if file.size == 0
    session[:error] = "A name is required"
    status 422
    erb :create
  else
    file_path = File.join(data_path, file)
    File.write(file_path, "#{file}")

    # This is not an error, rather a message.
    session[:error] = "#{file} was created."

    redirect '/'
  end
end

post '/:file' do
  require_signed_in_user

  file_path = File.join(data_path, params[:file])
  file = params[:file]

  File.write(file_path, params[:update])

  # This is not an error, rather a message.
  session[:error] = "#{file} has been updated."
  redirect '/'
end

post '/:file/delete' do
  require_signed_in_user

  file = params[:file]
  file_path = File.join(data_path, params[:file])

  File.delete(file_path)

  # This is not an error, rather a message.
  session[:error] = "#{file} has been deleted."
  redirect '/'
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  credentials = load_user_credentials
  username = params[:username]
  password = params[:password]

   if valid_credentials?(username, params[:password])
    # This is not an error, rather a message.
    session[:error] = "Welcome!"
    session[:username] = username
    redirect '/'
  else
    session[:error] = "Invalid Credentials"
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:username)

  # This is not a error, rather a message.
  session[:error] = "You have been signed out."

  redirect "/"
end