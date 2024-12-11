#!/bin/bash

cd fiber
git pull
cargo build --release
cp target/release/fnn tmp
ls -lh ./tmp/fnn
