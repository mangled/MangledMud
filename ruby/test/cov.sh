#!/bin/sh
rm coverage.info
lcov --base-directory . --directory ../obj/ -c -o coverage.info
genhtml coverage.info -o ./coverage

