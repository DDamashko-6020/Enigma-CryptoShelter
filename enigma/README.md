# Enigma CryptoShelter

Military-grade local encryption and password manager.
100% offline. No cloud. No servers. Your data stays on your device.

## Features
- AES-256-GCM + ChaCha20-Poly1305 double-layer file encryption (.ultra)
- Local password vault (like Proton Pass, but offline)
- Single master password — derives all keys via PBKDF2
- Cipher Lab: encrypt/decrypt text with 4 algorithms
- Cyberpunk dark UI (Tk desktop)

## Requirements
- Ruby 3.0+
- Tcl/Tk installed

## Installation

### macOS
```bash
brew install tcl-tk
gem install bundler
bundle install
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install tcl tk
gem install bundler
bundle install
```

### Windows
Install Ruby via RubyInstaller (check MSYS2 + Tk option), then:
```bash
ridk install
gem install bundler && bundle install
```

## Run
```bash
ruby main.rb
```

## Test
```bash
bundle exec rspec
```

## Build executable
```bash
# Windows
gem install ocra
ocra main.rb --gem-all --windows

# Mac / Linux (Traveling Ruby)
# See docs/packaging.md
```

## Architecture
```
Modular-Monolithic OOP | module Enigma namespace

app/core/       cipher, vault, file_lock, errors, key_master
app/ui/         Tk panels (cipher_lab, vault, file_lock)
utils/          shared utilities (file_handler, validator, password_generator)
spec/           RSpec tests (70%+ coverage)
```

## Security
- PBKDF2-HMAC-SHA256 with 600,000 iterations for key derivation
- AES-256-GCM: authenticated encryption (detects tampering)
- ChaCha20-Poly1305: authenticated encryption (Signal/WhatsApp standard)
- Vault file: 600 permissions, stored in `~/.enigma_cryptoshelter/`
- Offline-only: eliminates network attack surface entirely
