class CouchbaseQueryClient
  property parameters : CouchbaseQuery
  property? write : Bool = false

  ENDPOINT = "/query/service"
  HEADERS = HTTP::Headers{"Content-Type" => "application/json"}

  def initialize(@parameters : CouchbaseQuery, @write : Bool = false)
    uri = URI.parse "#{Couchbase.settings.use_tls ? "https" : "http"}://#{Couchbase.settings.db_host}:#{Couchbase.settings.db_query_port}"
    @client = HTTP::Client.new uri
    @client.basic_auth(Couchbase.settings.user, Couchbase.settings.password)
  end

  def perform
    puts parameters
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