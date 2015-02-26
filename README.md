# Packet Via DMEM
Finds junos packet-via-dmem packets from arbitrary output and generates text2pcap compatible output

## JunOS
To capture say packets with IP address 10.11.12.13

    % ssh test2nqe31.dk|tee output.txt
    fisakytt@test2nqe31-re1.dk> start shell pfe network afeb0

    AFEB platform (1000Mhz QorIQ P2020 processor, 2048MB memory, 512KB flash)
    MX104-ABB-0(test2nqe31-re1.dk vty)# test jnh 0 packet-via-dmem enable
    MX104-ABB-0(test2nqe31-re1.dk vty)# test jnh 0 packet-via-dmem capture 0x3 0x0a0b0c0d
    MX104-ABB-0(test2nqe31-re1.dk vty)# test jnh 0 packet-via-dmem capture 0x0
    MX104-ABB-0(test2nqe31-re1.dk vty)# test jnh 0 packet-via-dmem dump
    MX104-ABB-0(test2nqe31-re1.dk vty)# test jnh 0 packet-via-dmem disable


## CLI
    % ./bin/packet-via-dmem  -s 1 ~/output.txt|wc -l
    55
    % ./bin/packet-via-dmem ~/output.txt |wc -l
    28
    % ./bin/packet-via-dmem -r 0 ~/output.txt |wc -l
    0
    % ./bin/packet-via-dmem ~/output.txt|text2pcap - output.pcap
    Input from: Standard input
    Output to: output.pcap
    Output format: PCAP
    Wrote packet of 66 bytes.
    Wrote packet of 70 bytes.
    Wrote packet of 70 bytes.
    Wrote packet of 246 bytes.
    Wrote packet of 256 bytes.
    Wrote packet of 135 bytes.
    Wrote packet of 246 bytes.
    Wrote packet of 135 bytes.
    Wrote packet of 57 bytes.
    Wrote packet of 57 bytes.
    Wrote packet of 72 bytes.
    Wrote packet of 135 bytes.
    Wrote packet of 256 bytes.
    Wrote packet of 186 bytes.
    Wrote packet of 225 bytes.
    Wrote packet of 66 bytes.
    Wrote packet of 256 bytes.
    Wrote packet of 135 bytes.
    Wrote packet of 142 bytes.
    Wrote packet of 57 bytes.
    Wrote packet of 256 bytes.
    Wrote packet of 186 bytes.
    Wrote packet of 246 bytes.
    Wrote packet of 100 bytes.
    Wrote packet of 57 bytes.
    Wrote packet of 128 bytes.
    Wrote packet of 66 bytes.
    Wrote packet of 9 bytes.
    Read 28 potential packets, wrote 28 packets (4388 bytes).
    % ./bin/packet-via-dmem --help
    usage: ./bin/packet-via-dmem [options]
        -d, --debug     turn on debugging
        -r, --received  pop BYTES from received frames, default 6
        -s, --sent      pop BYTES from senti frames, default is not to show sent frames
        -h, --help
    %

## Library
    require 'packet_via_dmem'
    dmem = PacketViaDMEM.new
    puts dmem.parse File.read(ARGF[0])

## Todo
  1. correctly discover how many bytes need to be popped, perhaps by finding valid ethernet headers and ignore anything before?
  1. reverse engineer header/cookie, at least figuring out which fabric stream (And hence egress NPU) is going to be used should be trivial
