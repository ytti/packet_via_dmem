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


## Header format
Potentially first is type
  * 00 ?? ?? ?? source ??
  * 10 ?? ?? ?? ?? ?? source ??

Example receive headers, MX480

    00 0b 40 60 41 08
    00 01 c0 70 81 08
    00 02 40 70 81 08
    00 02 c0 70 81 08
    10 03 40 70 05 40 81 08
    00 03 c0 70 81 08
    00 06 40 70 81 08
    00 07 c0 70 81 08
    00 08 47 f0 20 00
    00 09 45 f0 20 00
    00 09 c7 f0 80 00
    00 0b c0 70 81 08
    10 0c 08 00 02 00 1f 00
    00 00 c0 70 81 08
    00 01 47 f0 80 00
    00 04 40 60 41 08
    10 04 c0 70 01 50 81 08
    00 05 40 70 81 08
    00 05 c0 70 81 08
    00 06 c5 f0 20 00
    10 07 08 00 02 00 1f 00
    00 08 c0 70 81 08
    00 0a 40 70 81 08
    00 0a c0 70 81 08
    00 0b 47 f0 20 00
    00 01 c0 70 81 08
    00 02 40 60 41 08
    00 07 c7 f0 b0 80

Example receive headers, MX80

    00 08 00 f0 81 08
    10 08 80 f0 05 b4 81 08
    10 09 00 f0 05 b4 81 08
    10 09 80 f0 05 b4 81 08
    00 0a 00 f0 92 08
    10 0a 80 f0 05 b4 81 08
    10 03 00 f0 05 b4 81 08
    00 04 00 f0 81 08
    10 04 80 f0 05 b4 81 08
    10 05 00 f0 05 b4 81 08
    10 05 80 f0 05 b4 81 08
    00 06 00 f0 81 08
    10 06 80 f0 05 b4 81 08
    00 07 00 f0 80 08
    10 07 80 f0 05 b4 81 08
    10 0b 00 f0 02 28 81 08

For this box, second to last byte, divmod 64, returns these ports, which are
correct port for source.

    TAZ-TBB-0(X vty)# show ixchip ifd
       IFD       IFD        IX     WAN       Ing Queue     Egr Queue
      Index      Name       Id     Port      Rt/Ct/Be      H/L 
      ======  ==========  ======  ======  ==============  ======
       148     ge-1/0/0      2       0        0/32/64       0/32
       149     ge-1/0/1      2       1        1/33/65       1/33
       166     ge-1/1/8      2      18       18/50/82      18/50


## Todo
  1. correctly discover how many bytes need to be popped, perhaps by finding valid ethernet headers and ignore anything before?
  1. reverse engineer header/cookie, at least figuring out which fabric stream (And hence egress NPU) is going to be used should be trivial
