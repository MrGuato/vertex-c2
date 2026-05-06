# VERTEX C2 — Threat Model

## Scope

This threat model covers the command and control link between an ArduPilot-based autonomous airframe and its ground control station (GCS), operating in a contested RF environment where an adversary has access to the same network segment.

## Assumptions

- Adversary has passive read access to the network segment
- Adversary has active injection capability on the network segment
- No physical access to the airframe or GCS hardware
- Standard COTS ArduPilot stack, no modifications

## Threat Actors

| Actor | Capability | Goal |
|-------|------------|------|
| Passive observer | Network sniffing | Collect telemetry, waypoints, operator patterns |
| Active adversary | Packet injection | Re-task, disarm, or crash the airframe |
| Infrastructure attacker | Network access | Pivot from GCS host to other systems |

## Threat Scenarios

### T-01 — Plaintext MAVLink Interception
**Vector:** SNIFF
MAVLink v2 transmits all commands unencrypted over UDP/14550 by default. An adversary with network access can capture ARM commands, MISSION_ITEM_INT waypoints, SET_MODE changes, and full telemetry in real time using any standard packet capture tool.

**Evidence:** See docs/screenshots/before-plaintext-mavlink.png

**Control:** WireGuard ChaCha20-Poly1305 tunnel — see infra/wireguard/

### T-02 — Unauthenticated Command Injection
**Vector:** INJECT
The default MAVLink stack accepts commands from any host that can reach UDP/14550. No certificate, key, or challenge is required. A second MAVProxy instance on the network can ARM, DISARM, or re-task the airframe without any credentials.

**Control:** WireGuard peer key authentication — only hosts with valid private keys can communicate through the tunnel.

### T-03 — Implicit Network Trust
**Vector:** TRUST-ON-FIRST-USE
GCS hosts commonly expose inbound MAVLink ports to the entire LAN or operator subnet. Trust is granted by network topology rather than cryptographic identity.

**Control:** Cloudflare Tunnel eliminates inbound port exposure. Traefik mTLS enforces mutual authentication at the GCS ingress layer.

## Residual Risk

This research artifact addresses link-layer and network-layer threats. It does not address:
- Physical RF jamming or denial of service
- Firmware-level compromise of the autopilot
- GPS spoofing (separate research area)
- Side-channel attacks on the GCS host

## CMMC Mapping

See docs/compliance/cmmc-mapping.md for NIST SP 800-171 control mapping.
