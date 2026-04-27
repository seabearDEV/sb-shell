#!/bin/sh

# sb-extract.sh - Universal archive extractor that dispatches on extension.
# Description: Extract or list archives without remembering tool-specific flags.
# Usage: sb-extract [-d DIR] [-t] FILE [FILE...]
#
# Parameters:
#   FILE       One or more archive files
#   -d DIR     Extract to DIR (default: current directory)
#   -t         List archive contents instead of extracting
#   -h         Show help

sb_extract() {
    DEST_DIR=""
    LIST_ONLY=0

    usage() {
        cat <<EOF
Usage: sb-extract [-d DIR] [-t] FILE [FILE...]

Extract archives based on file extension.

Options:
  -d DIR   Extract to DIR (default: current directory)
  -t       List contents instead of extracting
  -h       Show this help

Supported (archives):  tar, tar.gz/tgz, tar.bz2/tbz/tbz2, tar.xz/txz, zip, 7z, rar
Supported (single):    gz, bz2, xz   (extract only, -t not supported)

Examples:
  sb-extract archive.tar.gz
  sb-extract -d /tmp/x archive.zip
  sb-extract -t archive.7z
  sb-extract a.tar.gz b.zip c.7z
EOF
    }

    if [ $# -eq 0 ]; then
        usage
        return 0
    fi

    OPTIND=1
    while getopts ":d:th" opt; do
        case $opt in
            d) DEST_DIR="$OPTARG" ;;
            t) LIST_ONLY=1 ;;
            h) usage; return 0 ;;
            \?) echo "Invalid option: -$OPTARG" >&2; usage; return 1 ;;
            :)  echo "Option -$OPTARG requires an argument." >&2; usage; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ $# -eq 0 ]; then
        echo "Error: at least one file required" >&2
        return 1
    fi

    if [ -n "$DEST_DIR" ] && [ ! -d "$DEST_DIR" ]; then
        echo "Error: destination '$DEST_DIR' is not a directory" >&2
        return 1
    fi

    rc=0
    for f in "$@"; do
        if [ ! -f "$f" ]; then
            echo "Error: '$f' not found or not a regular file" >&2
            rc=1
            continue
        fi

        # Lowercase the filename for case-insensitive extension matching.
        lower=$(echo "$f" | tr '[:upper:]' '[:lower:]')

        case "$lower" in
            *.tar.gz|*.tgz)        sb_extract_dispatch tar "$f" -z ;;
            *.tar.bz2|*.tbz|*.tbz2) sb_extract_dispatch tar "$f" -j ;;
            *.tar.xz|*.txz)        sb_extract_dispatch tar "$f" -J ;;
            *.tar)                 sb_extract_dispatch tar "$f" ""  ;;
            *.zip)                 sb_extract_dispatch zip "$f"     ;;
            *.7z)                  sb_extract_dispatch 7z  "$f"     ;;
            *.rar)                 sb_extract_dispatch rar "$f"     ;;
            *.gz|*.bz2|*.xz)       sb_extract_dispatch single "$f" "$lower" ;;
            *)
                echo "Error: '$f' has no recognized archive extension" >&2
                rc=1
                continue
                ;;
        esac || rc=1
    done

    return $rc
}

sb_extract_dispatch() {
    kind="$1"
    f="$2"
    flag="$3"

    case "$kind" in
        tar)
            command -v tar >/dev/null 2>&1 || { echo "Error: tar not found" >&2; return 1; }
            if [ "$LIST_ONLY" -eq 1 ]; then
                # tar -t accepts the same compression flags as -x
                if [ -n "$flag" ]; then
                    tar "$flag" -tf "$f"
                else
                    tar -tf "$f"
                fi
            else
                if [ -n "$DEST_DIR" ]; then
                    if [ -n "$flag" ]; then
                        tar "$flag" -xf "$f" -C "$DEST_DIR"
                    else
                        tar -xf "$f" -C "$DEST_DIR"
                    fi
                else
                    if [ -n "$flag" ]; then
                        tar "$flag" -xf "$f"
                    else
                        tar -xf "$f"
                    fi
                fi
            fi
            ;;
        zip)
            command -v unzip >/dev/null 2>&1 || { echo "Error: unzip not found" >&2; return 1; }
            if [ "$LIST_ONLY" -eq 1 ]; then
                unzip -l "$f"
            elif [ -n "$DEST_DIR" ]; then
                unzip -q "$f" -d "$DEST_DIR"
            else
                unzip -q "$f"
            fi
            ;;
        7z)
            command -v 7z >/dev/null 2>&1 || { echo "Error: 7z not found (install p7zip)" >&2; return 1; }
            if [ "$LIST_ONLY" -eq 1 ]; then
                7z l "$f"
            elif [ -n "$DEST_DIR" ]; then
                7z x "-o$DEST_DIR" "$f"
            else
                7z x "$f"
            fi
            ;;
        rar)
            command -v unrar >/dev/null 2>&1 || { echo "Error: unrar not found" >&2; return 1; }
            if [ "$LIST_ONLY" -eq 1 ]; then
                unrar l "$f"
            elif [ -n "$DEST_DIR" ]; then
                # unrar has no -C flag; cd in a subshell so caller's cwd is unaffected.
                abs_f=$(cd "$(dirname "$f")" && pwd)/$(basename "$f")
                ( cd "$DEST_DIR" && unrar x "$abs_f" )
            else
                unrar x "$f"
            fi
            ;;
        single)
            if [ "$LIST_ONLY" -eq 1 ]; then
                echo "Error: -t (list) not supported for single-file compression: $f" >&2
                return 1
            fi
            lower="$flag"
            case "$lower" in
                *.gz)  tool=gunzip;  base=$(basename "$f" .gz)  ;;
                *.bz2) tool=bunzip2; base=$(basename "$f" .bz2) ;;
                *.xz)  tool=unxz;    base=$(basename "$f" .xz)  ;;
            esac
            command -v "$tool" >/dev/null 2>&1 || { echo "Error: $tool not found" >&2; return 1; }
            if [ -n "$DEST_DIR" ]; then
                # -c writes to stdout, leaving the original intact.
                "$tool" -c "$f" > "$DEST_DIR/$base"
            else
                # -k keeps the original file alongside the decompressed copy.
                "$tool" -k "$f"
            fi
            ;;
    esac
}
