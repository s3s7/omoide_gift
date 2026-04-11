class AddEmbeddingToGiftRecords < ActiveRecord::Migration[7.2]
 def change
    add_column :gift_records, :embedding, :vector, limit: 1536
    add_index :gift_records, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
