class GiftRecordSearchService
  DEFAULT_LIMIT = 50

  def self.search(query:, user:, limit: DEFAULT_LIMIT)
    query_vector = EmbeddingService.embed(query)
    return [] if query_vector.nil?

    vector_literal = "[#{query_vector.map { |v| Float(v) }.join(',')}]"

    scope = GiftRecord
      .where(user: user)
      .where.not(embedding: nil)

    matched_people = find_people_in_query(query, user)
    scope = scope.where(gift_people_id: matched_people.map(&:id)) if matched_people.any?

    scope
      .order(Arel.sql("embedding <=> '#{vector_literal}'::vector"))
      .limit(limit)
  end

  class << self
    private

    def find_people_in_query(query, user)
      GiftPerson.where(user: user).select { |p| query.include?(p.name) }
    end
  end
end
