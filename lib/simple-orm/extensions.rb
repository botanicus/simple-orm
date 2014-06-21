class SimpleORM
  def self.symbolise_keys(hash)
    hash.reduce(Hash.new) do |buffer, (key, value)|
      buffer.merge!(key.to_sym => value)
    end
  end
end
