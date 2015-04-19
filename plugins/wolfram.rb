# encoding: utf-8

module Plugins

  class Wolfram
    include Cinch::Plugin

    set :help, '!wolfram <term> - Returns top hit on google when searching for <term>'

    match /wolfram (.+)/

    def execute(m, query)
      m.reply search(query)
    end

    def search(query)
      wolfram = WolframAlpha::Client.new config[:api_id], options = { :timeout => 1 }
      response = wolfram.query query
      input = response["Input"] # Get the input interpretation pod.
      result = response.find { |pod| pod.title == "Result" } # Get the result pod.
      if result
        "#{input.subpods[0].plaintext}\n#{result.subpods[0].plaintext}"
      else
        "Sorry, I've no idea"
      end
    end
  end

end
