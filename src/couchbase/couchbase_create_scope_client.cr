class CouchbaseCreateScopeClient
  property parameters : CouchbaseScopeParameters

  HEADERS = HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}

  def initialize(@parameters : CouchbaseScopeParameters)
    uri = URI.parse "#{Couchbase.settings.use_tls ? "https" : "http"}://#{Couchbase.settings.db_host}:#{Couchbase.settings.db_admin_port}"
    @client = HTTP::Client.new uri
    @client.basic_auth(Couchbase.settings.user, Couchbase.settings.password)
  end

  def perform
    res = @client.post(endpoint, HEADERS, body: parameters.to_query_params)
    return res
  end

  private def endpoint
    "/pools/default/buckets/#{Couchbase.settings.bucket_name}/scopes"
  end
end