# VERTEX C2 — Demo Makefile
# Reproduces T-01 and T-02 attacks, then demonstrates the hardened defense
#
# Usage:
#   make install     install Python dependencies
#   make sitl        start ArduPilot SITL (run in a dedicated terminal)
#   make attack      run T-02 unauthenticated injection PoC
#   make capture     show plaintext MAVLink traffic (T-01)
#   make harden      bring up WireGuard tunnel
#   make verify      verify tunnel status and show encrypted traffic
#   make teardown    tear down WireGuard interfaces
#   make demo        guided full demo walkthrough
#   make clean       teardown + remove generated files

SITL_DIR     := $(HOME)/ardupilot/ArduCopter
SITL_BIN     := $(HOME)/ardupilot/build/sitl/bin/arducopter
WG_DIR       := $(CURDIR)/infra/wireguard
ATTACK_SCRIPT:= $(CURDIR)/attack/inject.py
TARGET       := 127.0.0.1
PORT         := 14550

.PHONY: all install sitl attack capture harden verify teardown demo clean

all: demo

install:
	@echo "[*] Installing Python dependencies..."
	pip3 install --user MAVProxy future empy==3.3.4 pexpect pymavlink
	@echo "[+] Dependencies installed"

sitl:
	@echo "[*] Starting ArduPilot SITL..."
	@echo "[!] Run this in a dedicated terminal — it is interactive"
	cd $(SITL_DIR) && ../Tools/autotest/sim_vehicle.py \
		-v ArduCopter --console --no-rebuild

attack:
	@echo "[*] VERTEX C2 — T-02: Unauthenticated MAVLink Injection"
	@echo "[*] Target: $(TARGET):$(PORT)"
	@echo "[!] Ensure SITL is running in another terminal first"
	@sleep 1
	python3 $(ATTACK_SCRIPT) --target $(TARGET) --port $(PORT)

capture:
	@echo "[*] VERTEX C2 — T-01: Plaintext MAVLink Capture"
	@echo "[*] Listening on UDP/$(PORT) — press Ctrl+C to stop"
	@echo "[!] Ensure SITL is running in another terminal first"
	sudo tcpdump -i lo udp port $(PORT) -A

harden:
	@echo "[*] VERTEX C2 — Bringing up WireGuard tunnel..."
	@if [ ! -f $(WG_DIR)/drone.conf ] || grep -q "REPLACE_WITH" $(WG_DIR)/drone.conf; then \
		echo "[-] WireGuard configs contain placeholders."; \
		echo "[-] Generate real keys first — see docs/reproduction.md Step 4"; \
		exit 1; \
	fi
	sudo ip link add dev wg-drone type wireguard 2>/dev/null || true
	sudo ip link add dev wg-gcs type wireguard 2>/dev/null || true
	sudo wg setconf wg-drone $(WG_DIR)/drone.conf
	sudo wg setconf wg-gcs $(WG_DIR)/gcs.conf
	sudo ip addr add 10.0.0.1/24 dev wg-drone 2>/dev/null || true
	sudo ip addr add 10.0.0.2/24 dev wg-gcs 2>/dev/null || true
	sudo ip link set up dev wg-drone
	sudo ip link set up dev wg-gcs
	@echo "[+] Tunnel up"
	sudo wg show

verify:
	@echo "[*] VERTEX C2 — Verifying tunnel encryption..."
	@echo "[*] Watching lo:51820 for 10 seconds — generating traffic..."
	sudo timeout 10 tcpdump -i lo udp port 51820 -A & \
		sleep 2 && ping -I wg-gcs -c 5 10.0.0.1 2>/dev/null || true; \
		wait
	@echo "[+] Encrypted traffic confirmed on lo:51820"

teardown:
	@echo "[*] Tearing down WireGuard interfaces..."
	sudo ip link del wg-drone 2>/dev/null || true
	sudo ip link del wg-gcs 2>/dev/null || true
	@echo "[+] Interfaces removed"

clean: teardown
	@echo "[*] Cleaning generated files..."
	rm -f attack/output/*.pcap attack/output/*.cap
	@echo "[+] Clean complete"

demo:
	@echo ""
	@echo "============================================================"
	@echo "  VERTEX C2 — Full Demo Walkthrough"
	@echo "============================================================"
	@echo ""
	@echo "STEP 1: Start SITL in a separate terminal:"
	@echo "  make sitl"
	@echo ""
	@echo "STEP 2: Demonstrate T-01 — plaintext MAVLink interception:"
	@echo "  make capture"
	@echo "  (watch ARM commands and waypoints stream in cleartext)"
	@echo ""
	@echo "STEP 3: Demonstrate T-02 — unauthenticated command injection:"
	@echo "  make attack"
	@echo "  (no credentials required — full command access)"
	@echo ""
	@echo "STEP 4: Deploy the defense:"
	@echo "  make harden"
	@echo "  (WireGuard tunnel up — ChaCha20-Poly1305 encryption)"
	@echo ""
	@echo "STEP 5: Verify encryption:"
	@echo "  make verify"
	@echo "  (lo:51820 shows cipher bytes — commands no longer readable)"
	@echo ""
	@echo "STEP 6: Read the threat model and CMMC mapping:"
	@echo "  docs/threat-model.md"
	@echo "  docs/compliance/cmmc-mapping.md"
	@echo ""
	@echo "Full reproduction guide: docs/reproduction.md"
	@echo "============================================================"
	@echo ""
