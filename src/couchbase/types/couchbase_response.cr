struct CouchbaseResponse
  include JSON::Serializable

  getter request_id : UUID
  getter results : Array(CouchbaseResult)
  getter errors : Array(CouchbaseError)

  def initialize(@request_id : UUID, @results : Array(CouchbaseResult), @errors : Array(CouchbaseError))
    # Initialize fields here if necessary
  end

  def self.from_json(json_string : String) : CouchbaseResponse
    json = JSON.parse(json_string)
    new(
      request_id: UUID.from_json(json["requestID"].to_json),
      results: json["results"]? ? json["results"].as_a.map{|r| CouchbaseResult.from_json(r.to_json)} : Array(CouchbaseResult).new,
      errors: json["errors"]? ? json["errors"].as_a.map{|e| CouchbaseError.from_json(e.to_json)} : Array(CouchbaseError).new,
    )
  end

  def get_records
    records = [] of String
    JSON.build do |json|
      json.array do
        @results.each do |result|
          json.object do
            record = result.to_record
            records << record
            json.field("db_errors", @errors)
          end
        end
      end
    end
    records
  end
end

struct CouchbaseResult
  include JSON::Serializable

  getter id : UUID
  getter document : JSON::Any

  def to_record
    JSON.build do |json|
      json.object do
        json.field("id", id)
        document.as_h.each do |key, value|
          json.field(key, value)
        end
      end
    end
  end
end

struct CouchbaseError
  include JSON::Serializable

  getter code : Int32
  getter column : Int32?
  getter line : Int32?
  getter msg : String
end