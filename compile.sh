#!/usr/bin/env bash

cat src/* | coffee -bc --stdio > bin/src.min.js
