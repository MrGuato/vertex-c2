# VERTEX C2 — CMMC Level 2 / NIST SP 800-171 Control Mapping

## Scope

Partial mapping of NIST SP 800-171 controls satisfied by the VERTEX C2 hardened stack.
This is a research artifact, not a certification package. FIPS-validated module substitution
is noted where applicable for environments requiring it.

## Control Mapping

| Control | Requirement | Implementation | Status |
|---------|-------------|----------------|--------|
| AC.L1-3.1.1 | Limit system access to authorized users | WireGuard peer key authentication — only hosts with valid private keys establish tunnel sessions | Satisfied |
| AC.L1-3.1.2 | Limit system access to authorized transactions | Traefik route-level rules scope GCS commands by authenticated peer | Satisfied |
| IA.L1-3.5.1 | Identify system users and processes | Per-operator WireGuard keys provide cryptographic identity at the link layer | Satisfied |
| IA.L1-3.5.2 | Authenticate users and devices | Mutual TLS at GCS ingress + WireGuard pre-shared peer keys | Satisfied |
| SC.L1-3.13.1 | Monitor and protect communications | WireGuard tunnel encrypts all MAVLink traffic — see after-wireguard-encrypted.png | Satisfied |
| SC.L1-3.13.5 | Implement subnetworks for publicly accessible system components | Cloudflare Tunnel — zero inbound ports exposed on GCS host | Satisfied |
| SC.L2-3.13.8 | Cryptographic protection of CUI in transit | ChaCha20-Poly1305 (data plane) + TLS 1.3 (control plane) | Satisfied |
| AU.L2-3.3.1 | Create and retain system audit logs | Loki + Promtail capture all GCS commands and link state changes | In Progress |
| AU.L2-3.3.2 | Ensure individual operator accountability | Per-operator certs + signed FluxCD commit history | In Progress |
| CM.L2-3.4.1 | Establish baseline configurations | FluxCD-managed declarative manifests — all config in Git | In Progress |
| SI.L1-3.14.1 | Identify and correct system flaws | Prometheus alerting on link anomalies and ingress events | In Progress |

## Notes

- **ChaCha20-Poly1305** is used in the research implementation for transparency and reproducibility.
  For environments requiring FIPS 140-2 validated modules, substitute AES-256-GCM via a
  FIPS-validated WireGuard build or IPsec with a validated crypto provider.
- Controls marked **In Progress** are implemented in the k3s stack currently under development.
- This mapping covers the C2 link security layer only. A full CMMC L2 assessment requires
  coverage of all 110 NIST SP 800-171 practices across the entire system boundary.

## References

- NIST SP 800-171 Rev 2
- CMMC Level 2 Practice Guide
- DoD CIO CMMC Model v2.0
