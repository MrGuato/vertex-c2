# VERTEX C2

**Hardened command and control architecture for autonomous systems operating in contested RF environments.**

Open security research demonstrating how MAVLink-based drone C2 links fail under adversarial conditions — and what a zero-trust, CMMC-aligned ground control stack looks like in practice.

## Threat Model

| ID | Vector | Description |
|----|--------|-------------|
| T-01 | SNIFF | MAVLink commands transmitted in plaintext on UDP/14550 |
| T-02 | INJECT | Any host on the network can issue commands — no peer auth |
| T-03 | TRUST | GCS trusts the network by topology, not by cryptographic signature |

## Stack

ArduPilot SITL · MAVLink v2 · WireGuard · Traefik · Cloudflare Tunnel · Prometheus · Loki · k3s · FluxCD

## Status

Active research. WireGuard tunnel implemented and verified. k3s GCS stack in progress.

## License

Apache 2.0
