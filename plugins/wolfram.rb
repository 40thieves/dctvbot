# encoding: utf-8

module Plugins

  class Wolfram
    include Cinch::Plugin
    include Cinch::Extensions::Authentication

    set :help, '!wolfram <query> - Attempts to answer your <query> using Wolfram Alpha'

    match /wolfram (.+)/

    def execute(m, query)
      return unless (@bot.search_enabled || authenticated?(msg))
      m.reply search(query)
    end

    def search(query)
      wolfram = WolframAlpha::Client.new(config[:api_id], options = { :timeout => 15 })
      response = wolfram.query query
      input = response["Input"] # Get the input interpretation pod.
      result = response.find { |pod| pod.title == "Result" }
      # possible titles (partial): Results, Basic information, Decimal approximation, Properties
      #                           Value, Definitions, Demographics
      result = response.pods[1] unless result
      if result
        output = "#{input.subpods[0].plaintext}"
        result.subpods.each do |subpod|
          output += "\n#{subpod.plaintext}"
        end
        output
      else
        "Sorry, I've no idea"
      end
    end
  end

end
