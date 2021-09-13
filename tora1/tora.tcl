set opt(chan)       Channel/WirelessChannel
set opt(prop)       Propagation/TwoRayGround
set opt(netif)      Phy/WirelessPhy
set opt(mac)        Mac/802_11
set opt(ifq)        Queue/DropTail/PriQueue
set opt(ll)         LL	      ;#Link Layer
set opt(ant)        Antenna/OmniAntenna
set opt(x)             700   ;# X dimension of the topography
set opt(y)             700  ;# Y dimension of the topography
set opt(ifqlen)      50   ;# max packet in ifq
set opt(nn)          10
set opt(connections)  5
set opt(stop)        300
set opt(dataRate)       [expr 1.0*256*8]  ;#packet size=256 bytes
set opt(adhocRouting)   TORA
set ns_		[new Simulator]
set topo	[new Topography]
set opt(fn) "wireless"
set tracefd	[open $opt(fn).tr w]
set f1 [open w1.tr w]
set f2 [open w2.tr w]
set f3 [open w3.tr w]
set namtrace    [open $opt(fn).nam w]

$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namtrace $opt(x) $opt(y)

# declare finish program
proc finish {} {
	global ns_ tracefd f1 f2 f3 namtrace
	$ns_ flush-trace
	close $tracefd
	close $namtrace

        close $f1
 	close $f2
        close $f3
	#exec nam $namtrace
	exit 0
}

# define topology
$topo load_flatgrid $opt(x) $opt(y)

# Create God(Generate Operations Director): stores table of shortest no of hops from 1 node to another
set god_ [create-god $opt(nn)]







# define how node should be created
#global node setting
$ns_ node-config -adhocRouting $opt(adhocRouting) \
                 -llType $opt(ll) \
                 -macType $opt(mac) \
                 -ifqType $opt(ifq) \
                 -ifqLen $opt(ifqlen) \
                 -antType $opt(ant) \
                 -propType $opt(prop) \
                 -phyType $opt(netif) \
                 -channelType $opt(chan) \
		 -topoInstance $topo \
		 -agentTrace ON \
                 -movementTrace ON \
                 -routerTrace ON \
                 -macTrace OFF


#  Create the specified number of nodes [$opt(nn)] and "attach" them to the channel.
for {set i 0} {$i < $opt(nn) } {incr i} {
	set node_($i) [$ns_ node]
#	$node_($i) random-motion 1		;# disable random motion
}


for {set i 0} {$i < $opt(nn) } {incr i} {
    $node_($i) set X_ [expr rand()*500]
    $node_($i) set Y_ [expr rand()*500]
    $node_($i) set Z_ 0
}

for {set i 0} {$i < $opt(nn)} {incr i} {
    $ns_ initial_node_pos $node_($i) 20
}

for {set i 0} {$i < $opt(connections)} {incr i} {

    #Setup a UDP connection
    set udp_($i) [new Agent/UDP]
    $ns_ attach-agent $node_($i) $udp_($i)
    set null_($i) [new Agent/Null]
    set c [expr $opt(nn)-$i-1]
    $ns_ attach-agent $node_($c) $null_($i)
    $ns_ connect $udp_($i) $null_($i)

    #Setup a CBR over UDP connection
    set cbr_($i) [new Application/Traffic/CBR]
    $cbr_($i) attach-agent $udp_($i)
    $cbr_($i) set type_ CBR
    $cbr_($i) set packet_size_ 256
    $cbr_($i) set rate_ $opt(dataRate)
    $cbr_($i) set random_ false
     $ns_ at 250.0 "$cbr_($i) start"
    $ns_ at $opt(stop) "$cbr_($i) stop"
}
#random motion
for {set j 0} {$j < 50} {incr j} {
    for {set i 0} {$i < $opt(nn)} {incr i} {
        set xx_ [expr rand()*$opt(x)]
        set yy_ [expr rand()*$opt(y)]
       set rng_time [expr rand()*$opt(stop)]

   $ns_ at $rng_time "$node_($i) setdest $xx_ $yy_ 5.0"   ;
    }
}

# Tell nodes when the simulation ends
for {set i 0} {$i < $opt(nn) } {incr i} {
    $ns_ at $opt(stop) "$node_($i) reset";
}

$ns_ at $opt(stop) "finish"
$ns_ run
