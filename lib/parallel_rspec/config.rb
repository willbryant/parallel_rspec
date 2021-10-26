module ParallelRSpec
  module Config
    @after_fork = []

    def self.after_fork(&block)
      if block
        @after_fork << block
      else
        @after_fork
      end
    end
  end
end
