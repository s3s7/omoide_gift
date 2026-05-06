class GiftRecordSearchService
  DEFAULT_LIMIT = 5

  def self.search(query:, user:, limit: DEFAULT_LIMIT)
    query_vector = EmbeddingService.embed(query)
    return [] if query_vector.nil?

    vector_literal = "[#{query_vector.join(',')}]"

    GiftRecord
      .where(user: user)
      .where.not(embedding: nil)
      .order(Arel.sql("embedding <=> '#{vector_literal}'::vector"))
      .limit(limit)
  end
end
