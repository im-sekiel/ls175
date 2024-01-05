require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

helpers do
  def in_paragraphs(text)
    text.split("\n\n").each_with_index.map do |line, index|
      "<p id=paragraph#{index}>#{line}</p>"
    end.join
  end

  def highlight(paragraph, query)
    paragraph.gsub(query, "<strong> #{query}</strong>")
  end
end


  def each_chapter
    @contents.each_with_index do |name, index|
      number = index + 1
      contents = File.read("data/chp#{number}.txt")
      yield number, name, contents
    end
  end

def chapters_matching(query)
  results = []

  return results unless query

  each_chapter do |number, name, contents|
    matches = {}
    contents.split("\n\n").each_with_index do |paragraph, index|
      matches[index] = paragraph if paragraph.include?(query)
    end
    results << {number: number, name: name, paragraphs: matches} if matches.any?
  end

  results
end


before do
  @contents = File.read("data/toc.txt").split("\n")
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get '/chapters/:number' do
  number = params[:number].to_i

  redirect "/" unless (1..@contents.size).cover? number

  @chapter = in_paragraphs(File.read("data/chp#{number}.txt"))
  @chapter_title = @contents[number - 1]
  @title = "Chapter #{number}: #{@chapter_title}"

  erb :chapter
end

get "/search" do
  @results = chapters_matching(params[:query])
  
  erb :search
end

get '/show/:name' do
  params[:name]
end

not_found do 
  redirect "/"
end