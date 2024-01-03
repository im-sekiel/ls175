# require "sinatra"
# require "sinatra/reloader"
# require "tilt/erubis"

# get "/" do
#   @list = Dir.glob("public/*").map(:sort)

#   erb :challenge
# end

# list.rb
require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  @list = Dir.glob("public/*").map { |file| file.gsub("public/", "") }.sort
  @list.reverse! if params[:sort] == "desc"
  erb :challenge
end