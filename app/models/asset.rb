module Asset
  class Base
    def self.costs(transaction)
      raise NotImplementedError
    end
  end
end
