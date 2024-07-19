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
      results: json["results"]? ? json["results"].as_a.map{|r| CouchbaseResult.from_db(r.to_json)}.compact : Array(CouchbaseResult).new,
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
  getter document : Hash(String, JSON::Any)

  def initialize(@id, @document); end

  def self.from_db(string_or_io)
    document = Hash(String, JSON::Any).new
    id = nil
    parser = JSON::PullParser.new(string_or_io)
    parser.read_object do |key|
      pp key
      case key
      when "id"
        id = UUID.new(parser.read_string)
      else
        pp "meh"
        document[key] = JSON.parse(parser.read_raw)
        pp "meh"
      end
    end

    self.new(id, document) unless id.nil?
  end

  def to_record
    JSON.build do |json|
      json.object do
        json.field("id", id)
        document.each do |key, value|
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