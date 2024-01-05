require "sinatra"
require 'sinatra/reloader'
require 'tilt/erubis'
require 'yaml'

before do
  @content = Psych.load_file("users.yaml")
  #=> {:jamy=>{:email=>"jamy.rustenburg@gmail.com", :interests=>["woodworking", "cooking", "reading"]}, 
  #=>  :nora=>{:email=>"nora.alnes@yahoo.com", :interests=>["cycling", "basketball", "economics"]}, 
  #+>  :hiroko=>{:email=>"hiroko.ohara@hotmail.com", :interests=>["politics", "history", "birding"]}}
  @users = []
  @emails = []
  @interests = []

  @content.each do |user, data|
    @users << user
    data.each do |subject, info|
      case subject
      when :email
        @emails << info
      when :interest
        @interests << info
      end
    end
  end
end

#### Helper methods

helpers do

  def count_interests
    sum = 0

    @users.each do |user|
      sum += @content[user][:interests].count
    end

    sum
  end

end

#### Routes below

get "/" do
 @users
 @emails
 @interests

 erb :home
end

get "/:user" do
  @user = params[:user]

  redirect "/not-found" unless @users.include?(@user.to_sym)

  erb :user
end

get "/not-found" do
  return 'There is nothing there'
end