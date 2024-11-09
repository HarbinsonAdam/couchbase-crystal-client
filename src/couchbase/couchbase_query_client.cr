class Couchbase::CouchbaseQueryClient
  property parameters : CouchbaseQuery
  property? write : Bool = false

  ENDPOINT = "/query/service"
  HEADERS = HTTP::Headers{"Content-Type" => "application/json"}

  def initialize(@parameters : CouchbaseQuery, @write : Bool = false); end

  def perform
    Log.debug { "SQL #{parameters.statement} #{parameters.args ? parameters.args : ""}" }
    start_time = Time.monotonic

    response_body = Couchbase.http_client_pool.with_client do |client|
      write? ? perform_post(client) : perform_get(client)
    end

    elapsed_time = Time.monotonic - start_time
    formatted_response = CouchbaseResponse.from_json(response_body)
    Log.debug { "SQL (#{elapsed_time.microseconds / 1000}ms) #{formatted_response.filtered_records}" }
    return formatted_response
  end

  private def perform_get(client : HTTP::Client) : String
    response = client.get(ENDPOINT, HEADERS, body: parameters.to_json)
    response.body
  end

  private def perform_post(client : HTTP::Client) : String
    response = client.post(ENDPOINT, HEADERS, body: parameters.to_json)
    response.body
  end
end
