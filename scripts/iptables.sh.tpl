#!/bin/bash

# Docker 1.13+ defaults FORWRD to DROP. Allow the cbr0 interface.
iptables -A FORWARD -i cbr0 -j ACCEPT
iptables -A FORWARD -o cbr0 -j ACCEPT