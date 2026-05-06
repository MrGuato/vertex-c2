# VERTEX C2 — Reproduction Guide

## Prerequisites

- RHEL 9/10 or Ubuntu 22.04+ (single host sufficient)
- Python 3.9+
- git, gcc, gcc-c++, make
- sudo access

## Step 1 — Install Dependencies

```bash
sudo dnf install -y git gcc gcc-c++ make python3 python3-pip \
  wireguard-tools ccache libxml2-devel libxslt-devel

pip3 install --user MAVProxy future empy==3.3.4 pexpect pymavlink
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc && source ~/.bashrc
```

## Step 2 — Build ArduPilot SITL

```bash
git clone https://github.com/ArduPilot/ardupilot.git
cd ardupilot
git submodule update --init --recursive
./waf configure --board sitl
./waf copter
```

## Step 3 — Reproduce the Attack (T-01 Plaintext Intercept)

Terminal 1 — start SITL:
```bash
cd ardupilot/ArduCopter
../Tools/autotest/sim_vehicle.py -v ArduCopter --console --no-rebuild
```

Terminal 2 — capture plaintext MAVLink:
```bash
sudo tcpdump -i lo udp port 14550 -A
```

You will see ARM commands, waypoints, and telemetry in plaintext.
This is T-01. Screenshot this output.

## Step 4 — Deploy the Defense (WireGuard Tunnel)

```bash
cd vertex-c2

# Generate keypairs
cd infra/wireguard
wg genkey | tee drone-private.key | wg pubkey > drone-public.key
wg genkey | tee gcs-private.key | wg pubkey > gcs-public.key
chmod 600 drone-private.key gcs-private.key

# Build configs
cat > drone.conf << WGEOF
[Interface]
PrivateKey = $(cat drone-private.key)
ListenPort = 51820

[Peer]
PublicKey = $(cat gcs-public.key)
AllowedIPs = 10.0.0.2/32
WGEOF

cat > gcs.conf << WGEOF
[Interface]
PrivateKey = $(cat gcs-private.key)
ListenPort = 51821

[Peer]
PublicKey = $(cat drone-public.key)
AllowedIPs = 10.0.0.1/32
Endpoint = 127.0.0.1:51820
WGEOF

# Bring up tunnel
sudo ip link add dev wg-drone type wireguard
sudo ip link add dev wg-gcs type wireguard
sudo wg setconf wg-drone drone.conf
sudo wg setconf wg-gcs gcs.conf
sudo ip addr add 10.0.0.1/24 dev wg-drone
sudo ip addr add 10.0.0.2/24 dev wg-gcs
sudo ip link set up dev wg-drone
sudo ip link set up dev wg-gcs

# Verify
sudo wg show
```

## Step 5 — Verify Encryption (T-01 Closed)

Terminal 1 — watch the wire:
```bash
sudo tcpdump -i lo udp port 51820 -A
```

Terminal 2 — generate tunnel traffic:
```bash
ping -I wg-gcs -c 10 10.0.0.1
```

Terminal 1 now shows encrypted cipher bytes — no readable commands.
Compare with Step 3. This is T-01 closed.

## Step 6 — Teardown

```bash
sudo ip link del wg-drone
sudo ip link del wg-gcs
```

## Notes

- Private keys are gitignored and never committed
- Single-host ping shows 100% packet loss due to kernel routing
  optimization — this is expected. Encrypted traffic is confirmed
  via tcpdump on lo port 51820.
- Two-host deployment resolves the routing behavior
- k3s GCS stack deployment: see infra/k3s/ (in progress)
