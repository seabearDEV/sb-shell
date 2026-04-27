#!/bin/sh

# sb-port.sh - Show what is listening on a TCP/UDP port.
# Description: Friendly wrapper around lsof for "what's on port N" queries.
# Usage: sb-port [-U] PORT [PORT...]
#
# Parameters:
#   PORT       A port number (1-65535) or range (e.g. 8000-8010)
#   -U         Use UDP instead of TCP (default: TCP listening only)
#   -h         Show help

sb_port() {
    USE_UDP=0

    usage() {
        cat <<EOF
Usage: sb-port [-U] PORT [PORT...]

Show what's listening on the given TCP (default) or UDP port(s).

Options:
  -U   Use UDP instead of TCP
  -h   Show this help

Arguments:
  PORT       A port number (1-65535)
  PORT-PORT  An inclusive range (e.g. 8000-8010), max 1000 ports per range

Examples:
  sb-port 8080
  sb-port 80 443 8080
  sb-port 8000-8010
  sb-port -U 53

Note: lsof only shows processes owned by the current user unless run with sudo.
EOF
    }

    if [ $# -eq 0 ]; then
        usage
        return 0
    fi

    OPTIND=1
    while getopts ":Uh" opt; do
        case $opt in
            U) USE_UDP=1 ;;
            h) usage; return 0 ;;
            \?) echo "Invalid option: -$OPTARG" >&2; usage; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ $# -eq 0 ]; then
        echo "Error: at least one port required" >&2
        return 1
    fi

    if ! command -v lsof >/dev/null 2>&1; then
        echo "Error: lsof not found" >&2
        return 1
    fi

    # Build a comma-separated port list from args (which may include ranges).
    ports=""
    for arg in "$@"; do
        case "$arg" in
            *-*)
                start="${arg%-*}"
                end="${arg#*-}"
                if ! echo "$start" | grep -Eq '^[0-9]+$' || ! echo "$end" | grep -Eq '^[0-9]+$'; then
                    echo "Error: invalid range '$arg'" >&2
                    return 1
                fi
                if [ "$start" -lt 1 ] || [ "$end" -gt 65535 ] || [ "$start" -gt "$end" ]; then
                    echo "Error: range '$arg' out of bounds (1-65535) or inverted" >&2
                    return 1
                fi
                if [ "$((end - start))" -gt 999 ]; then
                    echo "Error: range '$arg' too wide (max 1000 ports)" >&2
                    return 1
                fi
                p="$start"
                while [ "$p" -le "$end" ]; do
                    if [ -n "$ports" ]; then
                        ports="${ports},${p}"
                    else
                        ports="$p"
                    fi
                    p=$((p + 1))
                done
                ;;
            *)
                if ! echo "$arg" | grep -Eq '^[0-9]+$'; then
                    echo "Error: '$arg' is not a valid port number" >&2
                    return 1
                fi
                if [ "$arg" -lt 1 ] || [ "$arg" -gt 65535 ]; then
                    echo "Error: port '$arg' out of range (1-65535)" >&2
                    return 1
                fi
                if [ -n "$ports" ]; then
                    ports="${ports},${arg}"
                else
                    ports="$arg"
                fi
                ;;
        esac
    done

    if [ "$USE_UDP" -eq 1 ]; then
        proto_label="UDP"
        result=$(lsof -nP "-iUDP:${ports}" 2>/dev/null)
    else
        proto_label="TCP"
        result=$(lsof -nP "-iTCP:${ports}" -sTCP:LISTEN 2>/dev/null)
    fi

    if [ -z "$result" ]; then
        printf "Nothing listening on %s port(s): %s\n" "$proto_label" "$(echo "$ports" | tr ',' ' ')"
        if [ "$(id -u)" -ne 0 ]; then
            echo "(lsof only sees your own processes -- try sudo to see others.)" >&2
        fi
        return 0
    fi

    echo "$result"
}
