class CouchbaseClient
  property parameters : CouchbaseQuery
  property? write : Bool = false

  ENDPOINT = "/query/service"
  HEADERS = HTTP::Headers{"Content-Type" => "application/json"}

  def initialize(@parameters : CouchbaseQuery, @write : Bool = false)
    uri = URI.parse "http://127.0.0.1:8093"
    @client = HTTP::Client.new uri
    @client.basic_auth("Admin", "abc123")
  end

  def perform
    pp parameters
    res = write? ? perform_post : perform_get
    pp res
    return CouchbaseResponse.from_json(res.body)
  end

  private def perform_get
    @client.get(ENDPOINT, HEADERS, body: parameters.to_json)
  end

  private def perform_post
    @client.post(ENDPOINT, HEADERS, body: parameters.to_json)
  end
end