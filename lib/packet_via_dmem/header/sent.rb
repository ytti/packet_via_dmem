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

    def to_s
      type_str = 'unk'
      type_str = 'wan' if msg_type == 8
      type_str = 'fab' if msg_type == 0
      flags = ''
      flags << (statistics ? 'S' : 's')
      flags << (increment_reference ? 'I' : 'i')
      flags << (fragment_info ? 'F' : 'f')
      flags << (drop_hash ? 'H' : 'h')
      flags << (decrement_reference ? 'D' : 'd')
      flags << (prequeue_priority ? 'P' : 'p')
      #"TX: magic %d,%d   popped %d" % [(magic1 or -1), (magic2 or -1), (popped or -1)]
      "TX: %s # %s # P:%d(%s) # Ty:%x # Q(%d@%d) # C:%d # D:%d # O:%d # T:%d # L:%d" %
        [ type_str, flags, port, port.divmod(64).join('/'), type, queue_number,
          queue_system, color, queue_drop_opcode, offset, table, life ]
    end
  end
end
end
