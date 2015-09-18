module ParallelRSpec
  # Adapted from nitra.
  # Copyright 2012-2013 Roger Nesbitt, Powershop Limited, YouDo Limited.  MIT licence.
  class Channel
    ProtocolInvalidError = Class.new(StandardError)

    attr_reader :rd, :wr
    attr_accessor :raise_epipe_on_write_error

    def initialize(rd, wr)
      @rd = rd
      @wr = wr
      @rd.binmode
      @wr.binmode
    end

    def self.pipe
      c_rd, s_wr = IO.pipe("ASCII-8BIT", "ASCII-8BIT")
      s_rd, c_wr = IO.pipe("ASCII-8BIT", "ASCII-8BIT")
      [new(c_rd, c_wr), new(s_rd, s_wr)]
    end

    def self.read_select(channels)
      fds = IO.select(channels.collect(&:rd))
      fds.first.collect do |fd|
        channels.detect {|c| c.rd == fd}
      end
    end

    def close
      rd.close
      wr.close
    end

    def read
      return unless line = rd.gets
      if result = line.strip.match(/\ACOMMAND,(\d+)\z/)
        data = rd.read(result[1].to_i)
        Marshal.load(data)
      else
        raise ProtocolInvalidError, "Expected command length line, got #{line.inspect}"
      end
    end

    def write(data)
      encoded = Marshal.dump(data)
      wr.write("COMMAND,#{encoded.bytesize}\n")
      wr.write(encoded)
      wr.flush
    rescue Errno::EPIPE
      raise if raise_epipe_on_write_error
    end
  end
end
