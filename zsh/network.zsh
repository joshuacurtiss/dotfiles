#
# Network related functions and aliases
#

# Configs
: "${IP_DIR=$HOME/Documents/IP}"

# Clearing DNS cache on macOS
alias flushdnscache='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'

# Report active network interfaces WITH IP addresses
alias interfaces='for i in $(ifconfig -l); do; [[ -n $(ipconfig getifaddr $i) ]] && echo $i; true; done'

# Scan for IP Addresses on the local network (sort by IP address)
check_or_install_brew_command arp-scan && alias ipscan='sudo echo "Scanning. Please wait..."; sudo arp-scan --localnet --interface=$(interfaces | head -n 1) -x -g -r4 -t1200 -b2 -B64k | sort -k1 -V'

# Internal IP Address
alias ip='for i in $(ifconfig -l); do; ipconfig getifaddr $i; true; done'

# Returns IP address(es) of a given domain name
alias domainip='dig +short -4'

# Public IP Address
pubip() {
   curl ifconfig.io/ip
}

# Record my IP address to my Documents folder (Set IP_DIR to empty to disable)
function ip_save() {
   [[ -z $IP_DIR ]] && return
   mkdir -p "$IP_DIR"
   local name=$(basename "${HOST:-$(hostname)}" .local)
   name=${name:-Unknown}
   ip > "$IP_DIR/$name.txt"
}

ip_save
