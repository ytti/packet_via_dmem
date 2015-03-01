class PacketViaDMEM

  class Packet
    class NoPayload < Error; end
    attr_reader :type, :packet, :header, :popped, :original

    def pop bytes
      @original[bytes..-1]
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

    private

    def popped_and_packet packet, pop_bytes, push_bytes
      popped  = packet[0..pop_bytes-1]
      payload = packet[pop_bytes..-1]
      raise NoPayload, "no payload for #{packet}" unless payload
      payload = push_bytes + payload
      [popped, payload]
    end

    def get_pop_push pkt, header
      header.port = pkt.shift.to_i(16)
      header.type = pkt.shift.to_i(16)
      if Type::NOPOP.include? header.type # no-op, DMAC follows
        [0, []]
      else # *Type::MPLS, *Type::SELF, *Type::SENT (But be robust for unexpected)
        header.magic1 = pkt.shift.to_i(16)
        header.magic2 = pkt.shift.to_i(16)
        magic pkt, header
      end
    end

    def magic pkt, header
      case header.magic1
      when 0x00 # the super dodgy one
        magic_self pkt, header
      when 0x01 # we're missing ethertype, need more data to discover etype
        etype = FAKE[:etype_ipv4]
        etype = FAKE[:etype_mpls] if Type::MPLS.include? header.type
        push = pkt[0..11] + etype
        [ 12 , push ]
      when 0x20 # we have extra crap
        [ 21, [] ]
      when 0x80 # sent... only?
        header.magic3 = pkt.shift.to_i(16)
        [ 0, [] ]
      end
    end

    def magic_self pkt, header
      case header.port
      when 0x80
        [ 12 , [] ]
      when 0x1f
        push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype_ipv4] + FAKE[:ipv4]
        [ 5, push ]
      when 0x20
        push = FAKE[:dmac] + FAKE[:smac] + FAKE[:etype_ipv4]
        [ 3, push ]
      else
        $stderr.puts "magic_self: magic: (%x/%x), port: %x'" % [header.magic1, header.magic2, header.port] if @debug
      end
    end

    module Type
      SELF  = [ 0x00, 0x40 ]
      MPLS  = [ 0x20 ]
      SENT  = [ 0x12, 0x0e ]
      NOPOP = [ 0x08, 0x80 ]
    end

  end
end
