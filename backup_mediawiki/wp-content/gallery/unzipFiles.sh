#!/bin/bash

year=2017
mkdir -p "./${year}"
for month in {01..12}; do
        unzip ${year}_${month}.zip
done
