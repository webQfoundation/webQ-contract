# QRC-20 Protocol

---

[QRC-20][https://app.web-q.foundation] is an open protocol developed by Web-Q.Foundation that provides post-quantum transactions for Ethereum.

This repository is a monorepo including the QRC-20 protocol smart contracts.

[website-url]: https://app.web-q.foundation

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Contracts

| Contracts                                             | Base                                                                                                                     | Description                                                          |
| --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
|    QRC-20    |   QRC-Base       | Basic implemention of QRC-20 protocol           |
|     WebQ      |     Gnosis Safe     | Entry to Web-Q.Foundation, secured by gnosis-safe multi-sign contract      |
|      DelegatedWebQ     |    -      | Delegate yet equivalent  WebQ    |
|      WebQ NFT Hub     |     ERC721SeaDrop      | NFT contract under opensea standard |

## Usage

Node version 6.x or 8.x is required.

Most of the packages require additional typings for external dependencies.
You can include those by prepending the `@0x/typescript-typings` package to your [`typeRoots`](http://www.typescriptlang.org/docs/handbook/tsconfig-json.html) config.

```json
"typeRoots": ["node_modules/@0x/typescript-typings/types", "node_modules/@types"],
```

### Install dependencies

Make sure you are using Yarn v1.9.4. To install using brew:

```bash
brew install yarn@1.9.4
```

Then install dependencies

```bash
yarn install truffle
```

### Build


To build all contracts packages:

```bash
truffle build
```

