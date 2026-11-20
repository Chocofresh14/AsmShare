# AsmShare

[![CI](https://github.com/Chocofresh14/AsmShare/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Chocofresh14/AsmShare/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A file-sharing HTTP server written **entirely in x86-64 assembly (NASM)**, with no libc and no external library: a single static binary that serves a directory on your local network, like `python3 -m http.server`.

This is a **learning project**: the code is deliberately simple (no SIMD, no optimization, no complex macros), split into small functions with clear names.

> ⚠️ **Local network only.** AsmShare has no authentication and no encryption. Never expose it to the Internet (no port forwarding on your router).

## Features

- Listens on port **8080** and serves several clients in parallel (one `fork()` per connection, no zombie processes).
- `GET` requests over HTTP/1.0 or 1.1, one request per connection (`Connection: close`).
- **Files**: sends the headers (`200 OK`, `Content-Length`), then the content with `sendfile`.
- **Directories**: HTML page generated with `getdents64`, one link per entry (names starting with a dot are hidden).
- **Errors**: `400` (malformed request), `403` (path containing `..`), `404` (not found).
- No runtime dependency: `ldd asmshare` answers "not a dynamic executable".

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/Chocofresh14/AsmShare/refs/heads/develop/install.sh | bash
```

The script:

1. checks that `git`, `make`, `nasm` and `ld` are available, and installs them with `apt` if they are missing (Debian / Ubuntu);
2. clones the repository into `./AsmShare` (the default branch, `develop`);
3. builds it with `make`;
4. installs the binary to `/usr/local/bin/asmshare` (with `sudo`, so you may be asked for your password).

Notes:

- Requirements: Linux **x86-64**. On a distribution other than Debian / Ubuntu, install `git`, `make`, `nasm` and `binutils` yourself before running the script.
- The cloned `AsmShare/` folder stays in the directory where you ran the command. You can delete it once the installation is done.
- To be safe, read the script before running it:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/Chocofresh14/AsmShare/refs/heads/release/v1.0.0/install.sh -o install.sh
  less install.sh
  bash install.sh
  ```

To uninstall:

```bash
sudo rm /usr/local/bin/asmshare
```

## Usage

**AsmShare serves the `www/` directory of the current directory**, meaning the directory where you run the command, not the one where the binary is installed.

```bash
mkdir -p ~/share/www
cp my-file.pdf ~/share/www/
cd ~/share
asmshare
```

Then open `http://localhost:8080/` in a browser. From another device on the same local network, use the machine's IP address:

```bash
hostname -I        # example: http://192.168.1.42:8080/
```

To share an existing directory without copying it, create a link named `www`:

```bash
mkdir ~/share && cd ~/share
ln -s ~/Documents www
asmshare
```

Stop the server with `Ctrl+C`. If you run `asmshare` in a directory that has no `www/`, the server starts but every request returns `404`.

## Build from source

```bash
git clone https://github.com/Chocofresh14/AsmShare.git
cd AsmShare
make          # builds ./asmshare
make run      # builds, then runs from the project root
make test     # tests for utils.asm (strlen, memcpy, strcmp, itoa)
make clean    # removes build/ and the binary
```

You need `nasm`, `ld` (from the `binutils` package) and `make`.

## Testing with curl

With the server running from the project root:

```bash
curl -i http://127.0.0.1:8080/hello.txt                    # 200 + Content-Length
curl http://127.0.0.1:8080/                                # HTML listing
curl -i http://127.0.0.1:8080/nope                         # 404
curl -i --path-as-is http://127.0.0.1:8080/../Makefile     # 403
curl -i -X POST http://127.0.0.1:8080/                     # 400
```

The `--path-as-is` option stops `curl` from cleaning up the `..` itself before sending the request.

These checks also run automatically in the GitHub Actions workflow (`.github/workflows/ci.yml`) on every pull request.

## Project structure

```
AsmShare/
├── Makefile
├── install.sh           # one-command installation
├── include/
│   └── syscalls.inc     # syscall numbers and constants
├── src/
│   ├── main.asm         # socket, bind, listen, accept, fork
│   ├── request.asm      # read the request, extract the path, reject ".."
│   ├── response.asm     # HTTP headers, sendfile, 400/403/404 pages
│   ├── listing.asm      # getdents64 and HTML generation
│   └── utils.asm        # strlen, memcpy, strcmp, itoa
├── tests/
│   └── test_utils.asm   # test program for utils.asm
└── www/                 # sample shared directory (test files)
```

## Life of a request

1. `accept` takes the connection, then `fork`: the child process handles the client while the parent goes back to accepting the next one.
2. The child reads the request (`read`) and `parse_request` extracts the path (`GET /docs/note.txt HTTP/1.1`).
3. If the path contains `..`, the answer is `403`. If the request is malformed, the answer is `400`.
4. The path is prefixed with `www` and opened (`open`), then `fstat` gives its type:
   - **file**: headers, then `sendfile`;
   - **directory**: `getdents64` and an HTML page;
   - anything else: `404`.
5. The child closes the connection (`close`) and exits (`exit`).

Syscalls used: `socket`, `setsockopt`, `bind`, `listen`, `accept`, `read`, `write`, `open`, `close`, `fstat`, `sendfile`, `getdents64`, `fork`, `exit`, `rt_sigaction`.

## Security

- Paths containing `..` are rejected (`403`) before any file is opened.
- Paths are not decoded: `%2e%2e` stays a literal name and cannot escape `www/`. If `%xx` decoding is ever added, it must happen **before** the `..` check.
- Symbolic links placed **inside** `www/` are followed: do not put a link pointing outside the shared directory.
- No authentication, no HTTPS, no rate limiting and no timeout. Use it on a trusted network only.

## Known limitations

- No keep-alive: one request per connection.
- The request is read with a single `read` (4,095 bytes at most) and the path is limited to 1,023 bytes.
- Only `GET` is handled: other methods (`POST`, etc.) get a `400`.
- No URL decoding (`%20`): files whose names contain spaces or special characters cannot be reached, and names are written as-is into the listing's HTML.
- Files are sent as `application/octet-stream`: the browser downloads them instead of displaying them.
- The port (8080) and the directory (`www/` of the current directory) are not configurable.
- IPv4 only.

## License

[MIT](LICENSE)
