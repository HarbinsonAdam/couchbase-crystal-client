struct Couchbase::Join
  include JSON::Serializable

  property relationship_type : RelationshipType
  property join_type : JoinType
  property join_name : String
  property join_1_name : String
  property join_1_field : String
  property join_2_name : String
  property join_2_field : String

  enum JoinType
    LEFT
    INNER
    RIGHT
  end

  enum RelationshipType
    MANY
    ONE
  end

  def initialize(@relationship_type, @join_type, @join_name, @join_1_name, @join_1_field, @join_2_name, @join_2_field); end
end