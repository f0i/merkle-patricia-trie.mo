let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.8.2-20230217/package-set.dhall sha256:0a6f87bdacb4032f4b273d936225735ca4a0b0378de1f81e4bc4c6b4c5bad8a5

let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [
  { name = "testing"
  , version = "v0.1.2"
  , repo = "https://github.com/internet-computer/testing"
  , dependencies = [] : List Text
  },
  { name = "rlp"
  , version = "master"
  , repo = "https://github.com/relaxed04/rlp-motoko"
  , dependencies = [] : List Text
  },
  { name = "sha3"
  , version = "master"
  , repo = "https://github.com/hanbu97/motoko-sha3"
  , dependencies = [] : List Text
  }
] : List Package

in upstream # additions 