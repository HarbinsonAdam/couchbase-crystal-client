require "json"
require "http"
require "uuid"
require "habitat"

struct UUID
  def self.new(pull : JSON::PullParser)
    string = pull.read_string
    UUID.new(string)
  end

  def to_json(json : JSON::Builder) : Nil
    json.string(self)
  end
end

module Couchbase
  Habitat.create do
    setting user : String = "admin"
    setting password : String = "password"
  end
end

require "./couchbase/**"