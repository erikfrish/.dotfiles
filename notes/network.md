# Network Profiles

NetworkManager state on both machines after the 2026-11-16 wb VPN fix.
`scripts/setup-home-dns` reproduces the base-profile part; `scripts/setup-wb-dns`
adds the wb split-DNS zones. Everything not listed below is left at the
NetworkManager default.

## Home Network

- Router, DHCP and DNS: `10.69.11.1` (`*.home.arpa`, search
  `trusted.home.arpa home.arpa`).
- Clients get their address from DHCP; addresses are reserved on the router
  (`compik` = `10.69.11.10`, `laptopchik` = `10.69.11.145`). Do not add static
  addresses to the profiles.
- `pve.home.arpa` = `10.69.0.15` lives in another VLAN and is reached only
  through the router. A static address from `10.69.0.0/24` on a client makes
  that VLAN look on-link: ARP fails and pve becomes unreachable.

## Base Profiles

| | `compik`: `eth` (`enp14s0`) | `laptopchik`: `DILIMON` (`wlan0`) |
|---|---|---|
| `ipv4.method` | `auto` | `auto` |
| `ipv4.addresses` / `ipv4.gateway` | none | none |
| `ipv4.dns` | `10.69.11.1` | `10.69.11.1` |
| `ipv4.dns-search` | `~home.arpa` | `~home.arpa` |
| `ipv4.dns-priority` | `20` | `20` |
| `ipv4.ignore-auto-dns` | `no` | `no` |

Routes on both, all `via 10.69.11.1 metric 5`:

```text
10.69.0.0/16
10.69.0.0/24
10.69.1.0/24
10.69.33.0/24
10.13.0.0/16
91.230.107.224/32
```

The `/24` routes sit inside `10.69.0.0/16` with the same gateway. They are
redundant but present on both hosts; `setup-home-dns` adds only
`10.69.0.0/16 10.13.0.0/16 91.230.107.224/32`.

## wb VPN (OpenVPN, `openvpn.wb.ru` = `91.230.107.224`)

Same on both hosts:

| setting | value |
|---|---|
| `ipv4.never-default` | `yes` |
| `ipv4.route-table` | `0` (pushed routes go to `main`) |
| `ipv4.routing-rules` | none |
| `ipv4.dns-priority` | `10` |
| `ipv4.dns-search` | `~zone` per line of `~/.config/dotfiles/wb-dns-zones` |

The server pushes `10.0.0.0/8`, `172.24.0.0/14`, `172.28.0.0/18` and a few
hosts via `tun0`. The home routes above are more specific than `10.0.0.0/8`,
so `10.69.x.x` stays on the LAN while wb is up.

Both hosts use the same client certificate; connecting wb on both at once
likely drops one session.

VPN DNS priorities are set by hand per profile; no script touches VPN
profiles:

| | `compik` | `laptopchik` |
|---|---|---|
| `wb` ipv4 / ipv6 | `10` / `0` | `10` / `10` |
| `vpnchik` ipv4 / ipv6 | no profile | `200` / `0` |

## Why `91.230.107.224/32` Matters

kvn (sing-box on `kvn0`) installs rules ahead of `main`:

```text
9001: lookup 2022 suppress_prefixlength 0
9002: not dport 53 lookup main suppress_prefixlength 0
9003: from 0.0.0.0 iif lo lookup 2022     # table 2022: default via kvn0
```

Rule 9002 skips the `main` default route. Without a specific route to the wb
server, OpenVPN's unbound UDP socket handshakes through `kvn0`. As soon as wb
adds its own route to the server, the socket moves to `enp14s0`/`wlan0`, the
server keeps answering the old path, and the tunnel stalls: `tls-crypt unwrap
error: packet replay` in the NetworkManager journal and zero RX on `tun0`.
The `/32` in the base profile keeps the server on the LAN from the first
packet.

`compik` used to have a separate `wb` table (`20054`) with routing rules
`100/900/910/1000`; it was replaced by the `laptopchik` layout above.

Check after changes:

```sh
ip route get 91.230.107.224   # via 10.69.11.1, not kvn0
ip route get 10.69.0.15       # via 10.69.11.1
ip -s link show tun0          # RX grows while wb is up
```
