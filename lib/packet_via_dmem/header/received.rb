class PacketViaDMEM
class Header
  class Received
    attr_accessor :msg_type,
                  :table,
                  :stream,
                  :offset,
                  :size,
                  :port,
                  :type,
                  :magic1,
                  :magic2,
                  :magic3   # this is sent only AFAIK, but guarded here just in case

    def to_s(packet_number=1)
      str = ''
      str << '# RX %03d # '     % packet_number
      str << 'bytes: %d # '     % size if msg_type > 0
      str << 'stream: %d # '    % stream
      str << 'port: %d (%s) # ' % [port, port.divmod(64).join('/')]
      str << "type: %d\n"       % type
      str << '#          '
      str << 'table: %d # '     % table
      str << 'offset: %d # '    % offset
      str << 'magic: %x/%x'     % [magic1, magic2] if magic1
      str
    end
  end
end
end
