# Gettext

[![Actions Status](https://github.com/tmattio/gettext/workflows/CI/badge.svg)](https://github.com/tmattio/gettext/actions)

Internationalization and localization support for OCaml.

The implementation is largely based on [ocaml-gettext](https://github.com/gildor478/ocaml-gettext), but the high-level API differs and aims at being more user-friendly and more flexible than the original one.

- Generate translation maps from `po` files directly, no need to compile them.
- Generate translation maps from directories or (crunched)[https://github.com/mirage/ocaml-crunch] modules.

## Installation

### Using Opam

```bash
opam install gettext
```

### Using Esy

```bash
esy add @opam/gettext
```

## Contributing

Take a look at our [Contributing Guide](CONTRIBUTING.md).