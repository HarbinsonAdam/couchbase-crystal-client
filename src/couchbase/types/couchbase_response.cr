struct CouchbaseResponse
  include JSON::Serializable

  getter request_id : UUID
  getter results : Array(CouchbaseResult)

  def initialize(@request_id : UUID, @results : Array(CouchbaseResult))
    # Initialize fields here if necessary
  end

  def self.from_json(json_string : String) : CouchbaseResponse
    json = JSON.parse(json_string)
    new(request_id: UUID.from_json(json["requestID"].to_json), results: json["results"].as_a.map{|r| CouchbaseResult.from_json(r.to_json)})
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