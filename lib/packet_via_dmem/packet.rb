class PacketViaDMEM

  class Packet
    class NoPayload < Error; end
    attr_reader :type, :packet, :header, :original

    def pop bytes
      @original[bytes..-1]
    end

    def header_and_packet packet, pop_bytes, push_bytes
      header  = packet[0..pop_bytes-1]
      payload = packet[pop_bytes..-1]
      raise NoPayload, "no payload for #{packet}" unless payload
      payload = push_bytes + payload
      [header, payload]
    end

    def to_s
      pretty_packet
    end

    def pretty_packet
      pretty @packet
    end

    def pretty_original
      pretty @original
    end

    def pretty packet
      offset = -16
      out    = ''
      packet.each_slice(16) do |slice|
        hex, str = [], []
        slice.each_slice(8) do |subslice|
          hex << subslice
          str << subslice.inject(' ') do |r, s|
            int = s.to_i(16)
            r + ((int > 31 and int < 127) ? int.chr : '.')
          end
        end
        hex << [] if not hex[1]
        hex.each do |h|
          (8-h.size).times { h << '  ' }
        end
        out << "%04x  %s  %s   %s \n" % [offset+=16, hex[0].join(' '), hex[1].to_a.join(' '), str.join('  ')]
      end
      out
    end


  end
end
