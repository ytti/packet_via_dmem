class PacketViaDMEM
class Header
  class Sent
    attr_accessor :msg_type,
                  :statistics,
                  :increment_reference,
                  :fragment_info,
                  :drop_hash,
                  :decrement_reference,
                  :prequeue_priority,
                  :offset,
                  :table,
                  :color,
                  :queue_drop_opcode,
                  :queue_system,
                  :life,
                  :queue_number,
                  :port,
                  :type,
                  :magic1,
                  :magic2,
                  :magic3

    def to_s(packet_number=1)
      str = ''
      str << '# TX %03d # ' % packet_number
      str << (statistics ? 'S' : 's')
      str << (increment_reference ? 'I' : 'i')
      str << (fragment_info ? 'F' : 'f')
      str << (drop_hash ? 'H' : 'h')
      str << (decrement_reference ? 'D' : 'd')
      str << (prequeue_priority ? 'P' : 'p')
      str << ' # '
      str << 'port: %d (%s) # '   % [port, port.divmod(64) ]
      str << 'type: %d # '        % type
      str << 'QoS: %d@%d # '      % [queue_number, queue_system]
      str << "QueueDropOp: %d\n"  % [queue_drop_opcode]
      str << '#          '
      str << 'color: %d # '       % color
      str << 'offset: %d # '      % offset
      str << 'table: %d # '       % table
      str << 'life: %d # '        % life
      str << 'magic: '
      str << '%x/%x'              % [magic1, magic2] if magic1
      str << '/%x'                % magic3 if magic3
      str
    end
  end
end
end
