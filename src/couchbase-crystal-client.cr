require "json"
require "http"
require "uuid"
require "habitat"
require "log"

struct UUID
  def self.new(pull : JSON::PullParser)
    string = pull.read_string
    UUID.new(string)
  end

  def to_json(json : JSON::Builder) : Nil
    json.string(self)
  end
end

module Couchbase::Log
  # ANSI color codes
  BLUE = "\e[34m"  # for info and debug messages
  RESET = "\e[0m"   # to reset color after the message

  # Debug log method (green text)
  def self.debug(&)
    ::Log.debug { "#{BLUE}#{yield}#{RESET}" }
  end
end

module Couchbase
  Habitat.create do
    setting user : String = "Administrator"
    setting password : String = "password"
    setting db_host : String = "127.0.0.1"
    setting db_admin_port : Int32 = 8091
    setting db_query_port : Int32 = 8093
    setting use_tls : Bool = false
    setting bucket_name : String = "test_bucket1234"
    setting scope_name : String = "test_scope"
    setting connection_pool_size : Int32 = 4
  end

  @@http_pool : HttpClientPool? = nil

  def self.setup_http_client_pool
    uri = URI.parse("#{Couchbase.settings.use_tls ? "https" : "http"}://#{Couchbase.settings.db_host}:#{Couchbase.settings.db_query_port}")
    @@http_pool ||= HttpClientPool.new(Couchbase.settings.connection_pool_size, uri, Couchbase.settings.user, Couchbase.settings.password)
  end

  def self.http_client_pool : HttpClientPool
    @@http_pool || (raise "HTTP client pool not initialized. Call `Couchbase.setup_http_client_pool` first.")
  end
end

require "http/client"
require "mutex"

class HttpClientPool
  def initialize(pool_size : Int32, uri : URI, username : String, password : String)
    @pool_size = pool_size
    @uri = uri
    @username = username
    @password = password
    @pool = Channel(HTTP::Client).new(pool_size)

    @pool_size.times do
      client = create_client
      @pool.send(client)
    end
  end

  def with_client
    client = @pool.receive
    begin
      yield client
    ensure
      @pool.send(client)
    end
  end

  def close
    @pool_size.times do
      client = @pool.receive
      client.close
    end
  end

  private def create_client : HTTP::Client
    client = HTTP::Client.new(@uri)
    client.basic_auth(@username, @password)
    client
  end
end


require "./couchbase/**"
