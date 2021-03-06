# encoding: utf-8

module Plugins

  class Google
    include Cinch::Plugin
    include Cinch::Extensions::Authentication

    set :help, '!google <term> - Returns top hit on google when searching for <term>'

    match /google (.+)/

    def execute(m, query)
      return unless (@bot.search_enabled || authenticated?(m))
      m.reply search(query)
    end

    def search(query)
      url = "http://www.google.com/search?q=#{CGI.escape(query)}"
      document = Nokogiri::HTML(open(url), nil, 'utf-8')

      title = document.at_css('h3.r a').content.strip
      link = document.at_css('h3.r a')[:href]
      link =~ /^\/url\?q=(.+)&sa=.+/i
      title = CGI.unescape_html title
      link = URI.unescape $1
      "#{title}\n#{link}"
    rescue
      "No results found"
    end
  end

end
