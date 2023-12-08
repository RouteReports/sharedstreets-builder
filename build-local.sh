#!/usr/bin/env bash

set -e
set -x

/opt/homebrew/opt/gradle@7/bin/gradle allJars --stacktrace
