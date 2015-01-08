#!/usr/bin/env bash

[ ! -d out ] && mkdir out

dart2js --enable-experimental-mirrors --categories=Server --output-type=dart bin/polymorphic.dart -o out/PolymorphicBot.dart -m
