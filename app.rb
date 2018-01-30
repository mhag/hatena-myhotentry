# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'mechanize'
require 'rss'
require 'yaml'

get '/feed.rss' do
  content_type 'application/xml'

  load_yaml
  agent
  login
  generate_feed(fetch_entries).to_s
end

private

def agent
  @agent = Mechanize.new
end

def login
  cookie_path = __dir__ + '/cookie.yml'

  if File.exist?(cookie_path)
    @agent.cookie_jar.load(cookie_path)
    return
  end

  @agent.get('https://www.hatena.ne.jp/login') do |page|
    page.form do |form|
      form.field_with(name: 'name').value = @name
      form.field_with(name: 'password').value = @password
    end.submit
    @agent.cookie_jar.save_as(__dir__ + '/cookie.yml')
  end
end

def fetch_entries
  @agent.get(mypage) do |page|
    return page.search('a.js-clickable-link').map do |entry|
      { title: entry.inner_text, link: entry.get_attribute(:href) }
    end
  end
end

def generate_feed(entries)
  RSS::Maker.make('1.0') do |maker|
    maker.channel.about = mypage
    maker.channel.title = 'マイホットエントリー'
    maker.channel.description = 'マイホットエントリー'
    maker.channel.link = mypage

    entries.each do |entry|
      item = maker.items.new_item
      item.title = entry[:title]
      item.link = entry[:link]
    end
  end
end

def load_yaml
  yaml = YAML.load_file(__dir__ + '/hatena.yml')
  @name = yaml['name']
  @password = yaml['password']
end

def mypage
  "http://b.hatena.ne.jp/#{@name}/hotentry"
end
