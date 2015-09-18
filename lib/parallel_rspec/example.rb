module ParallelRSpec
  # only the good bits of RSpec's Example class, those needed by the reporters and formatters and
  # marshallable.
  Example = Struct.new(:id, :description, :exception, :location_rerun_argument, :metadata) do
    def self.delegate_to_metadata(key)
      define_method(key) { metadata[key] }
    end

    delegate_to_metadata :execution_result
    delegate_to_metadata :file_path
    delegate_to_metadata :full_description
    delegate_to_metadata :location
    delegate_to_metadata :pending
    delegate_to_metadata :skip
  end
end