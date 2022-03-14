%%%

    title = "Amateur Radio Next Generation Link Layer (ARNGLL)"
    abbrev = "N6DRC ARNGLL"
    category = "std"
    docName = "n6drc-arngll-x"
    ipr = "none"
    keyword = ["Amateur Radio", "Ham Radio"]

    date = 2021-06-23T00:00:00Z

    [pi]
    editing = "no"
    private = "yes"
    compact = "yes"
    subcompact = "yes"
    comments = "yes"

    [[author]]
    initials = "R."
    surname = "Quattlebaum"
    fullname = "Robert S. Quattlebaum (N6DRC)"
    role = "editor"
    organization = "Individual"
      [author.address]
      email = "darco@deepdarc.com"
      [author.address.postal]
      region = "California"
      country = "USA"

%%%

.# Abstract

Write me.

Note: This document is a work-in-progress.

.# Copyright Notice

Copyright (C) 2017,2021 Robert Quattlebaum. All rights reserved.

This use of this document is hereby granted under the terms of the
Creative Commons International Attribution 4.0 Public License, as
published by Creative Commons.

 *  <https://creativecommons.org/licenses/by/4.0/>

This work is provided as-is. Unless otherwise provided in writing, the
authors make no representations or warranties of any kind concerning
this work, express, implied, statutory or otherwise, including without
limitation warranties of title, merchantability, fitness for a
particular purpose, non infringement, or the absence of latent or
other defects, accuracy, or the present or absence of errors, whether
or not discoverable, all to the greatest extent permissible under
applicable law.

.# Implementations of this standard

The above copyright notice and license applies only to this specific
document. The implementation of mechanisms described herein, as well
as the replication and use of any contained datasets required for the
implementation of said mechanisms, are offered freely to be used for
any purpose, public or private, commercial or non-commercial.

{mainmatter}

# Introduction #

AX.25 is a rather complex and verbose protocol that wastes a lot of
bandwidth on things that aren't strictly necessary, like ASCII
encoding of callsigns. It also imposes some unfortunate arbitrary
limitations, such as a maximum callsign length of six characters.

This document outlines a new link layer intended to be better optimized for
low-bandwidth links and, thus, be in a better position for being used
with 6LoWPAN. It works well with callsigns up to 12 characters long.
It is also flexible enough to be used with non-IP-based protocols,
such as text messaging and simplex voice.

The following link-layer is *loosely* inspired by the 802.15.4 MAC
layer. In particular, the following concepts from 802.15.4 have been
influential:

 *  PAN-IDs being used to create independent networks sharing the same
    medium.
 *  Beacons and beacon requests used to discover nearby networks.
 *  Optional MAC-layer security, *via [AES-OCB](http://web.cs.ucdavis.edu/~rogaway/ocb/)*.
 *  Optional MAC-layer frame acknowledgement

Significant differences include:

 *  Addresses are based on [ham addresses](https://github.com/arngll/arnce-spec)
    ([html](https://rawgit.com/arngll/arnce-spec/master/n6drc-arnce.html)),
    which encode the callsign.
 *  802.15.4-style short-addresses are replaced by temporary addresses
    defined in ARNCE/HAM-64.
 *  All addresses are effectively 64-bits when expanded, but may be
    compressed by omitting the trailing 16-bit chunks that would
    otherwise be zero-filled.
 *  The concept of a PAN-ID is now referred to as a Network Identifier
    (*NETID*). Its valid values are from `0x0000` to `0xFFFF`.
 *  There is no facility for sending messages between nodes on
    different NETIDs at the MAC layer. (Cross-PAN-ID messaging is
    possible with 802.15.4, but not terribly useful)
 *  Ability to include a nonce in a beacon request that is echoed back
    in the corresponding beacon. (Used for secure frame counter
    synchronization)

**IMPORTANT**: There is a provision in this spec for using AES-OCB to
prevent unauthorized users from interacting with systems they are not
authorized to interact with. A mechanism is provided for using AES-OCB
for both authentication-only and also for authentication and
encryption. Using AES-OCB mode for the encryption of data on amateur
radio frequencies (with specific exceptions for space stations or
remote controlled aircraft) is against FCC regulations (See [FCC Sec.
97\.113](http://www.gpo.gov/fdsys/pkg/CFR-2014-title47-vol5/xml/CFR-2014-title47-vol5-sec97-113.xml)).
Even when used to communicate with a space station or a
radio-controlled aircraft, the authors strongly encourage the use of
an authentication-only mode that omits the actual encryption of the
message contents.

## Features ##

TBD

## Concepts and Terminology ##

 * *TSA*: Temporary Short Address
 * *NETID*: 16-bit Network Identifier
 * *ARNCE*: Amateur Radio Numeric Callsign Encoding (HamAddr)
 * *Coordinator*: A station that assigns TSAs.
 * *Relay*: A station that will digitally repeat a packet.
 * *Beacon*: A special transmission that contains information
             about the sending station.
 * *ARNGLL*: Amateur Radio Next Generation Link Layer

## Modes of Operation ##

ARNGLL is designed to support a handful of different modes of communication:

### Point-to-Point ###

Stations communicate with each other directly.

### Analog Repeaters ###

Stations communicate with each other indirectly via the use of
an analog repeater.

### Digital Relays ###

Stations communicate with each other indirectly using relay
stations that rebroadcast frames.

## Future Direction ##

In the long term, the following features may be desirable:

 *  Beacon-enabled endpoints, where devices only send their outbound
    data traffic when polled.
 *  Coordinator Realignment, allowing the coordinator to change the
    channel and/or NETID
 *  Time-synchronization

The details of such capabilities need not be fully defined, but this
protocol should be designed with these future capabilities in mind.

# General Description #

TBD

## Physical Layer Considerations ###

TBD, but initially targeting the standard Bell 202 packet format used by AX.25.

### MTU ####

The maximum transmissible unit is defined by the PHY layer in use and
the options. It is RECOMMENDED to use a PHY layer with an MTU no
shorter than around 256 octets. In any case, the MTU of the PHY MUST be no
smaller than 127 octets. A PHY MTU larger than 256 is allowed and may
improve performance.

Note that if a network beacon payload specifies an MTU which is
different than the default MTU and smaller than the physical MTU limit
imposed by the PHY, the MTU value from the network beacon payload
SHOULD be used instead.

## Broadcast and Multicast ###

The ARNCE/HAM-64 specification outlines broadcast and multicast addresses:

 *  `FFFF-0000-0000-0000` - Broadcast Address
 *  `FAxx-xxxx-xxxx-xxxx` - IPv6 Multicast Address Range
 *  `FBxx-xxxx-0000-0000` - IPv4 Multicast Address Range

To converting IPv6 multicast addresses into link-local multicast
addresses, you store the lower 13 octets of the multicast
group-id *in reverse order*. This takes advantage of the fact that
IPv6 multicast addresses tend to be zero-filled. For example, a
destination multicast of `ff02::2` would simply be the abbreviated ham
address `FA02`.

See the ARNCE/HAM-64 address specification for more detailed information.

# General Frame Format #

Endpoints use a special 64-bit encoding of the callsign as link-layer
addresses, as defined
[in HAM-64](https://github.com/arngll/arnce-spec/blob/master/ham-addr.txt.md).
These addresses are often zero-padded, and thus can often be stored in
a shorter form using as few as 16-bits.

A link layer packet is arranged like this:

| Field     | Description            | Req. | Octets      |
|-----------|------------------------|------|-------------|
| `FCF`     | Frame Control Field    | *    | 2           |
| `NETID`   | Network ID             |      | 0/2         |
| `DSTADDR` | Destination Address    | *    | 2/4/6/8     |
| `SRCADDR` | Source Address         | *    | 2/4/6/8     |
| `RLYADDR` | Relay Address          |      | 0/2/4/6/8   |
| `SECINFO` | Security Header        |      | 0/5/6       |
| `PAYLOAD` | Payload                |      | n           |
| `MIC`     | Message Integrity Code |      | 0/4/8/12/16 |
| `FCS`     | Final Checksum         | *    | 2           |

## Frame Control Field

      0                                       1
      0   1   2   3   4   5   6   7   8   9   0   1   2   3   4   5
    +---+---+---+---+---+---+---+---|---+---+---+---+---+---+---+---+
    |  VER  |   T   | DSTLN | SRCLN | S | N | A | R | D |   | RLYLN |
    +---+---+---+---+---+---+---+---|---+---+---+---+---+---+---+---+
    :              MSB              :              LSB              :

Most Significant (First) Byte:

 *  `VER`: Version (`0x0` is experimental, `0x1` is to-spec)
 *  `T`: Frame Type
     *  `0` - Beacon
     *  `1` - Data
     *  `2` - Ack
     *  `3` - MAC Command
 *  `DSTLN`: 2 Bits - Destination Address Length
     *  `0` - 16-bit length
     *  `1` - 32-bit length
     *  `2` - 48-bit length
     *  `3` - 64-bit length
 *  `SRCLN`: 2 Bits - Source Address Length
     *  `0` - 16-bit length
     *  `1` - 32-bit length
     *  `2` - 48-bit length
     *  `3` - 64-bit length
 *  `RLYLN`: 2 Bits - Repeater Address Length
     *  `0` - 16-bit length
     *  `1` - 32-bit length
     *  `2` - 48-bit length
     *  `3` - 64-bit length

Least Significant (Second) Byte:

 *  `S`: Security Header Included Flag
 *  `N`: `NETID` Present
 *  `A`: Ack Requested
 *  `R`: Relay Address Present.
 *  `D`: Direction. True if the packet is being sent by the named relay station.
 *  All other bits are *RESERVED* (ignored upon receipt and set to
    zero on transmit)

## NETID: Network Identifier Field

The `NETID` field is optional. When absent, the meaning is
dependent on the packet type:

 *  In data packets (or in any type of secured packet), the NETID MAY
    be omitted if equal to `0x0000`. A missing NETID in such a packet
    MUST be interpreted as if the NETID were set to `0x0000`.
 *  A missing NETID in an unsecured, broadcast beacon request is
    interpreted as a request for a beacon from all NETIDs in range.

Note that, in the later case, any non-data packet that is sent as a
response to request MUST include the NETID field.

## DSTADDR: Destination Address Field

The destination address field is a HAM-64 address, and may be any of the following:

* Encoded callsign
* Special address (broadcast, multicast, etc)
* Temporary address (0x1-0x0639), if supported by the coordinator

The destination address MUST NOT be set to the "empty" address (0x0000).

All tailing chunks with the value 0x0000 SHOULD be omitted and the `DSTLN` field
of the Frame Control Field set accordingly.

## SRCADDR: Source Address Field

The source address field is a HAM-64 address, and may any of the following:

* Encoded callsign
* Temporary address (0x1-0x0639), if supported by the coordinator

The destination address MUST NOT be set to the "empty" address (0x0000),
the broadcast address, or any multicast address.

All tailing chunks with the value 0x0000 SHOULD be omitted and the `SRCLN` field
of the Frame Control Field set accordingly.

## RLYADDR: Relay Address Field

The relay address field is a HAM-64 address, and may any of the following:

* Encoded callsign
* Temporary address (0x1-0x0639), if supported by the coordinator

This field is used to identify a specific relay station that will be used
to relay the frame. This field is only present if the `R` flag is set.
If present, the `D` flag is used to differentiate between packets
that are being sent to the relay versus packets that have been relayed.
This field is only used when a packet is being relayed.

The relay address MUST NOT be set to the "empty" address (0x0000),
the broadcast address, or any multicast address.

All tailing chunks with the value 0x0000 SHOULD be omitted and the `RLYLN` field
of the Frame Control Field set accordingly.

## SECINFO: Security Header Field

The security header field is present when security is enabled by the
sender of the packet (bit `S` from the FCF). The exact details of
this field are outlined in [section 6.1](#security-header).

## PAYLOAD: Frame Payload Field

The content of the payload is defined by the frame type. See the
frame types section for more information.

## MIC: Message Integrity Code

The MIC establishes the cryptographic authenticity of the frame.
If present, can be 4, 8, or 16 bytes in length.

## FCS: Final Checksum Field

NOTE: This may change!

The FCS is a 16-bit big-endian value that is calculated over all of
the preceding bytes[^1] using the following CRC polynomial:

    G_16(x) = x^16 + x^12 + x^5 + 1

This CRC is also known as [CRC-16/CCITT-FALSE][FCS]. It is the same CRC
algorithm used for 802.15.4.

TODO: Consider using HDLC CRC for compatibility with existing TNCs?

[FCS]: http://reveng.sourceforge.net/crc-catalogue/16.htm#crc.cat.crc-16-ccitt-false
[^1]: [ACK packets](#ack-packets) are an exception to this behavior, see below

# Frame Types

There are four different types of frames:

1.  Beacon Frames
2.  Data Frames
3.  Acknowledgement Frames
4.  MAC Command Frames

## Beacon Frames

Beacons are used to announce or confirm the existence of a station,
as well as exchange other information such as network association
information (Like NETID) and higher-level protocol details (like MTU).
Strictly speaking, the payload of a beacon frame is optional. However,
the format of the payload, if present, is defined below.

The first part of the beacon frame format is the network protocol
identifier. This value is a variable-length integer that can be
represented by 1 to 3 bytes. The encoding format is identical to the
[EXI unsigned integer
encoding](http://www.w3.org/TR/exi/#encodingUnsignedInteger). This
allows values from 0 to 127 to be represented directly as a single
byte, values 128 to 16383 with two bytes, and values 16,384 to
2,097,151 with three bytes.

Encodings of unsigned integer values larger than three bytes MUST
NOT be used. If encountered, the frame MUST be dropped.

Any additional data appended to the payload in a beacon is defined
to be the *Beacon Parameters*, the format of which is described
in a section below.

A *Beacon Request* can include a *nonce*. If the beacon is sent in
response to a beacon request that includes a nonce, the a value `0x00`
followed by the nonce is appended to the end of the beacon payload.
This allows devices to securely learn the current security frame
counter from their peers.

### Protocol Numbers

The following protocol numbers are defined:

| No. | Name               | Reference                 |
|----:|--------------------|---------------------------|
|   0 | *RESERVED*         | —                         |
|   1 | Multi-Protocol     | TBD                       |
|   4 | IPv4/ARP           | RFC791                    |
|   5 | IPv6               | RFC8200                   |
|   6 | AR-6LoWPAN         | RFC4944, RFC6282, RFC6775 |
|   7 | CoAP-over-ARNGLL   | RFC7252, TBD              |
|  90 | Experimental Text  | TBD                       |
|  91 | Experimental Voice | TBD                       |
|  92 | Experimental AX.25 | TBD                       |

### Beacon Parameters Format

The beacon parameters are encoded using the same general mechanism that is
used to encode CoAP options (as defined in [RFC7252 section
3\.1](https://tools.ietf.org/html/rfc7252#section-3.1)), but with
different type associations. All fields are optional. Even-numbered
fields are defined by this section. Odd-numbered fields are defined by
the associated protocol.

The following field types are defined to be used across all protocols:

| No. | Name         | Format  | Length | Default      |
|----:|--------------|---------|--------|--------------|
|   0 | *RESERVED*   |         |        |              |
|   2 | Caps         | flags   | 1      | 0            |
|   4 | Network-Name | hamaddr | 0-8    | Empty        |
|   6 | TSA          | uint    | 0-2    | Unspecified  |
|   8 | PHY-MTU      | uint    | 0-2    | PHY specific |

* **Caps**: A set of flags describing the capabilities of this station.
   * Bit 0: Is Relay
   * Bit 1: Is Coordinator
   * Bit 2-7: Reserved (set to 0, ignore when set)
 * **Network-Name**: A human-readable, UTF8-encoded string
    describing the network. 0 to 16 bytes. Default value is empty.
 * **PHY-MTU**: Maximum Transmissible Unit for Physical Layer. MUST
    be no less than 127. If not present, assume it is whatever the
    defined default value is for the PHY layer that is in use.
 * **TSA**: Temporary Short Address of the sender, as defined in
    section 4.3.2 of ARNCE. This may be appended by a relay.

For 6LoWPAN-based protocols, the following fields are defined (with all
other fields being unallocated/reserved):

| No. | Name     | Format | Length | Default |
|----:|----------|--------|--------|---------|
|   1 | IPv6-MTU | uint   | 0-2    | 1280    |

*  **IPv6 MTU**: Effective Maximum Transmissible Unit for IPv6
    packets. MUST be no less than 1280. If not present, assume 1280.

## Data Frames

Data frames are the mechanism for transmitting the packets for
higher-level protocols, like IPv4 and IPv6.

The format of the data payload is dependent on the protocol being used
for the network, as described by the beacon protocol.

### Protocol 1: Multi-Protocol

Protocol 1 networks can multiplex different protocols onto the same
network, identified by the first few bytes of the frame. It is encoded
using the same mechanism used for beacon responses. For protocol
numbers 0-127, it is simply the first byte of the data frame. The rest
of the bytes in the data frame are interpreted according to the protocol
type.

### Protocol 4: IPv4/ARP

Protocol 4 networks are IPv4-only, with the data field containing the
either a raw IPv4 packet or a raw ARP packet. IPv4 packets are
differentiated from ARP packets by examining the most-significant nibble
of the first data byte: IPv4 packets will be 0x4, whereas ARP packets
will be 0x0.

#### ARP Details

* HTYPE: 0x2201
  * TODO: Register this value https://www.iana.org/assignments/arp-parameters/arp-parameters.xhtml
* PTYPE: 0x0800
* HLEN: 8
* PLEN: 4 

### Protocol 5: IPv6

Protocol 5 networks are IPv6-only, using no header compression. As such,
it is not well optimized for bandwidth-limited connections and is
specified here for experimental purposes only.

### Protocol 6: AR-6LoWPAN

Protocol 6 networks are IPv6-only, but encode the packets using a flavor
of 6LoWPAN optimized for ARNGLL we call AR-6LoWPAN. It has the following
differences:

 * 64-bit ARNCE/HAM-64 addresses are used instead of EUI-64 "long addresses"
   from 802.15.4.
 * 12-bit ARNCE TSAs are used instead of 16-bit "short addresses"
   from 802.15.4.

TBD

## Acknowledgement Frames

ACK packets are sent immediately in response to unicast packets which have the ACK
bit set. It is used to implement a MAC-level automatic
retry mechanism. Thus it is *critical* that if a packet is received
with the ACK bit set that an ACK packet be sent in response as quickly
as physically possible, so as to avoid causing the sender to retry.
Exact timing requirements are TBD.

Acknowledgement packets are special in that they have a simplified
frame structure and DO NOT follow the general structure adhered to by
all other types of frames. Fundamentally, an ACK packet contains only
three pieces of information: The address of the sender of the
acknowledgement, checksum of the original packet which is being
acknowledged, and a final checksum.

An acknowledgement frame is arranged like this:

| Field     | Description                | Octets  |
|-----------|----------------------------|---------|
| `FCF_MSB` | MSB of Frame Control Field | 1       |
| `SRCADDR` | Source Address             | 2/4/6/8 |
| `ACS`     | Acknowledgment Checksum    | 2       |
| `FCS`     | Final Checksum             | 2       |

This packet is designed to be as small as possible. Thus, the second
byte of the frame control field is omitted entirely, along with the
destination address and NETID. The ACS value is calculated from the
contents of the packet being acknowledged.

For ACK packets, the destination address length flag MUST be set to
zero. Upon receipt of an ACK packet, a value other than zero being
present in the destination address length field MUST cause the entire
packet to be ignored.

## Command Frames

MAC command frames are similar in function and purpose to the MAC
command packets in 802.15.4.

MAC commands generally follow a command-response pattern: A command
is received, and a response is sent. Thus, MAC command usually SHOULD
NOT have the acknowledgement request bit set.

The payload format for a MAC command is:

     0                      1
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-~..
    |  MAC Command  | MAC Command Specific Payload
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-~..

The following commands have been defined:

| No. | Name                   |
|----:|------------------------|
|   0 | (Reserved)             |
|   1 | Beacon Request         |
|   2 | Signal Report Request  |
|   3 | Signal Report Response |

### Beacon Request Command

Beacon requests are used for a variety of purposes:

 *  Discovering nearby ARNGLL networks and their associated properties
 *  Discovering nearby nodes on a specific network
 *  Frame counter synchronization (for networks that use security)

The beacon request payload is optional. If a payload is present, it is
assumed to be a nonce. Beacons sent in response to a beacon request
that includes a nonce MUST include the nonce at the end of the beacon
payload, preceded by a zero byte.

The nonce, if present in the request, MUST NOT be longer than 8 bytes
long. Such requests SHOULD be ignored by the receiving station.

To improve the performance of networks which use authentication, the
responding station MAY omit the NETID and beacon parameters (including the NETID)
from the beacon response if ALL of the following criteria are met:

 *  A nonce is present in the beacon request
 *  The NETID field is present in the beacon request

To avoid response collisions, a beacon sent in response to a
multicast/broadcast beacon request must use a random back-off delay
(between 0 and `MAX_MCAST_RESPONSE_BACKOFF` seconds) before sending
the beacon response. If supported by the PHY layer in use, the use of
a clear channel assessment (CCA) feature is highly RECOMMENDED.


Unicast beacon requests should be responded to as quickly as physically
possible. Exact timing requirements are TBD.

 *  `MAX_MCAST_RESPONSE_BACKOFF`: 0.1 seconds

### Signal Report Commands

The signal report request/response mechanism allows a station to
determine the link quality metrics at the MAC layer between nodes.

Responding to a signal report request is OPTIONAL and MAY be ignored
by the responder.

The format of the MAC command specific payload for the signal report
response command is:

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-.-+-+-+-+-+-+-+-.-+-+-+-+-+-+-+-.-+-+-+-+-+-+-+-+
    |      RSSI     |  Noise Floor  |      LQI      |   TX  Power   |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

 *  **RSSI** (8-bits, signed, dBm): The RSSI of the request, as
    received by the responder. A value of -128 means the RSSI is
    unknown or unsupported.
 *  **Noise Floor** (8-bits, signed, dBm): The noise floor of the
    responder. A value of -128 means the noise floor is unknown or
    unsupported.
 *  **LQI** (8-bits, unsigned, 0-255): A physical-layer-dependent
    measurement of the "quality" of the received signal. A value of
    zero means unknown or unsupported, a value of 255 means the signal
    was perfect, and while a value of 1 means that the signal was in
    the absolute worst shape possible while still being able to
    interpret it correctly. All other values represent varying
    quality levels, with numerically larger values indicating "better"
    quality. The exact method for how this value is calculated is
    defined by the PHY layer that is being used.
 *  **TX Power** (8-bits, signed, dBm): The transmit power of the
    responder. A value of -128 means the transmit power is unknown or
    unsupported. Knowing the transmit power of the responder can
    allow the requester to calculate the attenuation of the signal
    path.

There is no MAC-command-specific-payload for a signal report
*request*.

# Security Suite

ARNGLL provides a security suite which can be used to implement
authentication and/or privacy assurances for frames which are sent and
received. It is important to note that, when this protocol is used in
an amateur radio context, the use of encryption is prohibited under
almost all circumstances. It is anticipated that the most common use
of ARNGLL's security suite will be to prove frame authenticity and not
packet encryption.

The security layer is inspired by and somewhat similar to the security
layer in 802.15.4. If you are familiar with the security layer in
802\.15.4, you will find this section to be somewhat similar, but with
a few key differences:

1.  Uses *AES-OCB* mode instead of *AES-CCM\**, since AES-OCB mode is
    more efficient than AES-CCM\*, and the patents which cover AES-OCB
    are free to use for amateur radio purposes.
2.  There is no mechanism for specifying an encryption mode which
    doesn't include authentication. (Authentication without encryption
    *is* supported)

## Security Header

The security header (`SECINFO`) is defined as:

| Field  | Description            | Octets |
|--------|------------------------|--------|
| `SCF`  | Security Control Field | 1      |
| `FCNT` | Frame Counter          | 4      |
| `KID`  | Key Index              | 0/1    |

Where `SCF` is defined as:

      0
      0   1   2   3   4   5   6   7
    +---+---+---+---+---+---+---+---+
    | E | MICLN |  KIM  |  RESERVED |
    +---+---+---+---+---+---+---+---+

 *  `E`: Payload Encrypted Flag. Set if the payload is encrypted.
 *  `MICLN`: Length of the Message Integrity Check code, measured in
    4-octet chunks.
     *  `0x0`: 32-bit MIC
     *  `0x1`: 64-bit MIC
     *  `0x2`: 96-bit MIC
     *  `0x3`: 128-bit MIC
 *  `KIM`: Key Identifier Mode
     *  `0x0`: Key is identified by...
	     * R=0: `SRCADDR` and `DSTADDR`
	     * R=1;D=0: `SRCADDR` and `RLYADDR`
	     * R=1;D=1: `RLYADDR` and `DSTADDR`
     *  `0x1`: Key is identified by key index (`KID`).
     *  `0x2`: Reserved. Do not set.
     *  `0x3`: Reserved. Do not set.
 *  `RESERVED`: Reserved. Always set to zero when sending, and ignore
    upon reception (if the newly defined bits were really important,
    then decryption/authentication will fail)
 *  `FCNTR`: 32-bit integer indicating the sequential index of
    this frame. This counter MUST be incremented monotonically for
    each packet sent. Once a value is used, it must NEVER be reused
    (unless the encryption key is changed, at which point this value
    should be reset to `0x00000000`). This counter must never overflow
    from `0xFFFFFFFF` to `0x00000000`: Upon reaching `0xFFFFFFFF`, all
    further attempts to send a packet with a security header should
    fail until the security key is changed.
 *  `KID`: Key identifier. Defines which key to use from a pre-established
    set of keys. Value is 0-255.

For packets with a security header, the frame counter on received
packet MUST be compared to the peer frame counter. If the frame
counter on the packet is less than the frame counter in the peer
table, the packet MUST be dropped, EXCEPT for the following types of
packets:

 *  Beacon Request MAC Command Packet
 *  Beacon Packet (with matching nonce)

Note that, if either of the above packets include a security header
and the security MAC check fails, then the packet is ALWAYS dropped if
security is enabled.

Devices in a security-enabled network can learn the frame counter of
their peers by sending a beacon request command with a nonce.

## Security Operations

### AES-OCB Parameters

When we use AES-OCB, the following values are considered constants:

 *  *L* = 2 (the number of octets used to represent the length of the
    message)

AES-OCB encryption has the following inputs:

 *  Key
 *  Nonce (defined in [section 6.2.2](#622-nonce-definition))
 *  *a* data (Authenticated Data)
 *  *m* data (Plaintext data)
 *  *M* (Length of the message integrity check)

The output is "*c* data", which is the MIC (trimmed to *M* bytes)
appended to the end of the cyphertext.

AES-OCB decryption/authentication has the following inputs:

 *  Key
 *  Nonce (defined in [section 6.2.2](#622-nonce-definition))
 *  *a* data (Authenticated Data)
 *  *c* data (Cyphertext data and message integrity check)
 *  *M* (Length of the message integrity check)

The output is "*m* data", which is the plaintext data.

### Nonce ####

The nonce is defined as follows:

| Octets: | 8             | 1   | 4    |
|---------|---------------|-----|------|
| Fields: | FULL\_SRCADDR | SCF | FCNT |

Where `FULL_SRCADDR` is `SRCADDR` padded with trailing zeros to 64-bits (8 bytes).

### *a* data and *m* data ####

When used for authentication only (i.e.: `E` is set to `0`), *a* data
and *m* data are set to the following:

 *  `a` data: `FCF` || `NETID` || `DSTADDR` || `SRCADDR` ||
    `SCF` || `PAYLOAD` (Note, these fields are used as they
	appear in the packet. If the `NETID` is omitted from the packet,
	it should be omitted here)
 *  `m` data: *empty*

When encryption is used (i.e.: `E` is set to `1`), *a* data and *m*
data are set to the following:

 *  `a` data: `FCF` || `NETID` || `DSTADDR` || `SRCADDR` ||
    `SCF`
 *  `m` data: `PAYLOAD`

# Security Considerations ##

This section will eventually discuss the security considerations that
should be taken into account when implementing and using this
protocol.

# Acknowledgements ##

This section will eventually contain a list of people who have
contributed feedback to this document.

# References ##

## Normative References ###

 *  [ARNCE](https://github.com/arngll/arnce-spec/)
 *  [OCB Encryption Mode](http://web.cs.ucdavis.edu/~rogaway/ocb/)
 *  [RFC7253](https://tools.ietf.org/html/rfc7253) (For OCB Encryption
    Mode)

## Informative References ###

 *  [AX.25](https://www.tapr.org/pdf/AX25.2.2.pdf)
 *  [802.15.4-2003 Spec](http://user.engineering.uiowa.edu/~mcover/lab4/802.15.4-2003.pdf)

{backmatter}

# Examples and Test Vectors ##

## Beacon Request Frame ###

     0000: 31 00 FF FF 5C AC 70 F8
     0008: 07 29 18 FA 9C cs cs

 *  Ver: 0x0 (Experimental)
 *  Type: 0x3 (MAC command)
 *  NetID: Unspecified (will get beacons from all networks)
 *  Destination: All Nodes (`FFFF`)
 *  Source: N6DRC (`5CAC:70F8`)
 *  MAC command: 7 (Beacon request)
 *  Nonce: 0x2918fa9c
 *  Total length (including FCS): 15 bytes

## Beacon Frame

     0000: 05 40 13 37 5C AC 70 F8
     0008: 5C B6 26 E8 06 28 39 41
     0010: 4D 2D 54 41 4B 00 29 18
     0018: FA 9C cs cs

 *  Ver: 0x0 (Experimental)
 *  Type: 0x0 (Beacon)
 *  NetID: 0x1337
 *  Destination: N6DRC (`5CAC:70F8`)
 *  Source: N6NFI (`5CB6:26E8`)
 *  Network Type: 6 (6LoWPAN)
 *  Network Name: "9AM-TALK"
 *  Nonce: 0x2918fa9c
 *  Total length (including FCS): 28 bytes

## Data Frame

     15 60 13 37 5C B6 26 E8
     5C AC 70 F8 xx xx xx xx
     cs cs

 *  Ver: 0x0 (Experimental)
 *  Type: 0x1 (Data packet)
 *  NetID: 0x1337
 *  Ack requested
 *  Destination: N6NFI (`5CB6:26E8`)
 *  Source: N6DRC (`5CAC:70F8`)
 *  Data: 6LoWPAN Packet
 *  Total length (including FCS): ?? bytes

## Acknowledgement Frame

     21 5C B6 26 E8 cs cs

 *  Ver: 0x0 (Experimental)
 *  Type: 0x2 (Ack packet)
 *  Source: N6NFI (`5CB6:26E8`)
 *  Total length (including FCS): 7 bytes

# Comparative Analysis
## AX.25

The typical packet overhead (assuming 6-character callsigns, no
security, and no network id) of a single unicast packet is just 12
bytes:

 *  `FCF`: 2
 *  `DSTADDR`: 4
 *  `SRCADDR`: 4
 *  `FCS`: 2

Compare this to the typical AX.25 packet overhead, which is 17
bytes (41% larger!). Additionally, ARNGLL gracefully supports
callsigns larger than 6 characters (up to 12), which AX.25
quite simply cannot handle. When used with a coordinator, the
average packet length can decrease further to 10 or even 8.

Turning on security can add between 10 and 30 bytes per packet,
depending on how the security mode is configured.

The absolute worst-case maximum packet overhead (assuming
12-character callsigns, security, and a non-zero network id) for a
single unicast packet is 44 bytes:

 *  `FCF`: 2
 *  `NETID`: 2
 *  `DSTADDR`: 8
 *  `SRCADDR`: 8
 *  `SECINFO`: 6
 *  `MIC`: 16 (MIC-128)
 *  `FCS`: 2

Keep in mind that this is an worst-case upper-limit. When used with
typical security settings and common callsign length, an "average
worst case" would be something closer to around 24 bytes.
