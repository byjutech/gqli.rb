# frozen_string_literal: true

require 'http'
require 'json'
require_relative './response'
require_relative './introspection'
require_relative './version'

module GQLi
  # GraphQL HTTP Client
  class Client
    attr_reader :url, :params, :headers, :validate_query, :schema

    def initialize(url, params: {}, headers: {}, validate_query: true)
      @url = url
      @params = params
      @headers = headers
      @validate_query = validate_query

      @schema = Introspection.new(self) if validate_query
    end

    # Executes a query
    # If validations are enabled, will perform validation check before request.
    def execute(query)
      fail 'Validation Error: query is invalid - HTTP Request not sent' unless valid?(query)

      execute!(query)
    end

    # Executres a query
    # Ignores validations
    def execute!(query)
      http_response = HTTP.headers(request_headers).post(@url, params: @params, json: { query: query.to_gql })

      fail "Error: #{http_response.reason}\nBody: #{http_response.body}" if http_response.status >= 300

      data = JSON.parse(http_response.to_s)['data']

      Response.new(data, query)
    end

    # Validates a query against the schema
    def valid?(query)
      return true unless validate_query

      @schema.valid?(query)
    end

    protected

    def request_headers
      {
        accept: 'application/json',
        user_agent: "gqli.rb/#{VERSION}; http.rb/#{HTTP::VERSION}"
      }.merge(@headers)
    end
  end
end
