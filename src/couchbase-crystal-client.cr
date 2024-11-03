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
  end
end

require "./couchbase/**"
