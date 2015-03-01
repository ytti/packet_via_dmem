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
                  :popped,
                  :magic1,
                  :magic2

    def to_s
      ssize = ''
      ssize = "size: %d # " % size if msg_type > 0
      "RX: magic %d,%d   popped %d" % [(magic1 or -1), (magic2 or -1), (popped or -1)]     
      #"RX: %sport: %d (%s) # strm: %d # type: 0x%x # tbl: %d # o: %d" %
      #  [ ssize, port, port.divmod(64).join('/'), stream, type, table, offset ]
    end
  end
end
end
