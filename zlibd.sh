#!/bin/bash

FILE="${1:?Filename required}"
# gzip info
# https://web.archive.org/web/20200220015003/http://www.onicos.com/staff/iz/formats/gzip.html
GZIP_MAGIC_NUMBER='\x1f\x8b'
GZIP_COMPRESSION_METHOD='\x08'  # deflate
GZIP_FLAGS='\x00'  # file probably ascii text
GZIP_MTIME_EPOCH='\x00\x00\x00\x00'  # 1970-01-01 00:00:00 (date -d @0 +'%F %T')

printf "${GZIP_MAGIC_NUMBER}${GZIP_COMPRESSION_METHOD}${GZIP_FLAGS}${GZIP_MTIME_EPOCH}" \
    | cat - ${FILE} \
    | gzip -dc
