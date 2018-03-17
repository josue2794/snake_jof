#!/bin/bash

# Generar archivo asc:

gpg -a --detach-sign $1

# Generar archivo tsr:

openssl ts -query -data $1 -no_nonce -sha512 -out $1.tsq
curl -H "Content-Type: application/timestamp-query" --data-binary '@'$1'.tsq' https://freetsa.org/tsr > $1.tsr

# Generar archivo sha1:

sha1sum $1 > $1.sha1
