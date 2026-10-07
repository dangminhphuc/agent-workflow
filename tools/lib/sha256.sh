#!/usr/bin/env sh
# sha256_file <file> -> in sha256 (hex thường). Dùng công cụ có sẵn trên máy:
# sha256sum (Linux), shasum (macOS), openssl. Không có cái nào thì mã 1.
sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{ print $1 }'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{ print $1 }'
  elif command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 "$1" | awk '{ print $NF }'
  else return 1
  fi
}

# sha256_stdin -> sha256 của stdin (hex thường)
sha256_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{ print $1 }'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{ print $1 }'
  elif command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 | awk '{ print $NF }'
  else return 1
  fi
}
