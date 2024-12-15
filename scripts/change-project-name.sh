#!/bin/bash

set -e

rg "template-cpp-project" --files-with-matches | xargs sed -i "s/template-cpp-project/$1/g"
