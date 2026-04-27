#!/bin/sh

# sb-mksep.sh - Monitor and Kill System Exhausting Processes
# Description: Monitors processes and kills them when they exceed CPU or memory thresholds
# Usage: sb-mksep [-n PROCESS_NAME] [-c CPU_THRESHOLD] [-m MEMORY_THRESHOLD] [-s SLEEP_TIME] [-t] [-o] [-a] [-k KILL_COUNT] [-w VIOLATIONS/WINDOW]
# 
# Parameters:
#   -n PROCESS_NAME     Process name to monitor (default: monitors all processes)
#   -c CPU_THRESHOLD    CPU usage percentage threshold (default: 80%)
#   -m MEMORY_THRESHOLD Memory usage percentage threshold (default: 80%)
#   -s SLEEP_TIME       Sleep time between checks in seconds (default: 30)
#   -t                  Test mode - shows what would be killed without actually killing
#   -o                  Compact mode - only show processes with CPU >= 1% or Memory >= 1%
#   -a                  Aggregate mode - apply thresholds to combined usage of processes
#   -k KILL_COUNT       Number of processes to kill when aggregate threshold exceeded (default: kill until under threshold)
#   -w VIOLATIONS/WINDOW Time window mode - kill only after X violations within Y checks (e.g., -w 3/5)
#   -h                  Show help

# Function to monitor and kill system exhausting processes
sb_mksep() {
    # Default values
    PROCESS_NAME=""
    CPU_THRESHOLD=""
    MEMORY_THRESHOLD=""
    SLEEP_TIME=30
    TEST_MODE=0
    MONITOR_CPU=0
    MONITOR_MEM=0
    COMPACT_MODE=0
    AGGREGATE_MODE=0
    MIN_CPU_DISPLAY=0
    MIN_MEM_DISPLAY=0
    KILL_COUNT=""
    TIME_WINDOW=""
    VIOLATIONS_NEEDED=""
    WINDOW_SIZE=""

    # Display usage information
    usage() {
        cat << EOF
Usage: sb-mksep [-n PROCESS_NAME] [-c CPU_THRESHOLD] [-m MEMORY_THRESHOLD] [-s SLEEP_TIME] [-t] [-o] [-a] [-k KILL_COUNT] [-w VIOLATIONS/WINDOW] [-h]

Monitor and kill processes that exceed CPU or memory thresholds.

Options:
  -n PROCESS_NAME     Process name to monitor (case-insensitive, default: monitors all processes)
  -c CPU_THRESHOLD    Monitor CPU usage and kill if exceeds threshold (only monitors if set)
  -m MEMORY_THRESHOLD Monitor memory usage and kill if exceeds threshold (only monitors if set)
  -s SLEEP_TIME       Sleep time between checks in seconds (default: 30)
  -t                  Test mode - shows what would be killed without actually killing
  -o                  Compact mode - only show processes with CPU >= 1% or Memory >= 1%
  -a                  Aggregate mode - apply thresholds to combined usage of matching processes
  -k KILL_COUNT       Number of processes to kill when aggregate threshold exceeded (default: kill until under threshold)
  -w VIOLATIONS/WINDOW Time window mode - kill only after X violations within Y checks (e.g., -w 3/5)
  -h                  Show this help message

Modes:
  Individual mode (default): Each process checked separately against thresholds
  Aggregate mode (-a): Combined usage of matching processes checked against thresholds

Examples:
  sb-mksep -n firefox -c 90 -m 85    Monitor firefox, kill individual processes if CPU>90% or Memory>85%
  sb-mksep -n chrome -a -c 80         Aggregate mode: kill Chrome processes when combined CPU>80%
  sb-mksep -a -m 90 -k 2              Kill 2 highest memory processes when total system memory>90%
  sb-mksep -c 95 -t                   Test mode: monitor all processes, show if any exceed 95% CPU
  sb-mksep -n firefox -c 90 -w 3/5   Kill firefox only after 3 violations within 5 checks
EOF
    }

    # If no arguments provided, show help
    if [ $# -eq 0 ]; then
        usage
        return 0
    fi
    
    # Reset getopts
    OPTIND=1
    
    # Parse command line options
    while getopts ":n:c:m:s:k:w:toah" opt; do
        case $opt in
            n) PROCESS_NAME="$OPTARG" ;;
            c) CPU_THRESHOLD="$OPTARG"; MONITOR_CPU=1 ;;
            m) MEMORY_THRESHOLD="$OPTARG"; MONITOR_MEM=1 ;;
            s) SLEEP_TIME="$OPTARG" ;;
            k) KILL_COUNT="$OPTARG" ;;
            w) TIME_WINDOW="$OPTARG" ;;
            t) TEST_MODE=1 ;;
            o) COMPACT_MODE=1; MIN_CPU_DISPLAY=1; MIN_MEM_DISPLAY=1 ;;
            a) AGGREGATE_MODE=1 ;;
            h) usage; return 0 ;;
            \?) echo "Invalid option: -$OPTARG" >&2; usage; return 1 ;;
            :) echo "Option -$OPTARG requires an argument." >&2; usage; return 1 ;;
        esac
    done
    
    # Check if at least one threshold is set
    if [ "$MONITOR_CPU" -eq 0 ] && [ "$MONITOR_MEM" -eq 0 ]; then
        echo "Error: You must specify at least one threshold (-c for CPU or -m for memory)" >&2
        usage
        return 1
    fi

    # Validate numeric inputs only for set thresholds
    if [ "$MONITOR_CPU" -eq 1 ]; then
        if ! echo "$CPU_THRESHOLD" | grep -Eq '^[0-9]+$' || [ "$CPU_THRESHOLD" -lt 1 ] || [ "$CPU_THRESHOLD" -gt 100 ]; then
            echo "Error: CPU threshold must be a number between 1 and 100" >&2
            return 1
        fi
    fi

    if [ "$MONITOR_MEM" -eq 1 ]; then
        if ! echo "$MEMORY_THRESHOLD" | grep -Eq '^[0-9]+$' || [ "$MEMORY_THRESHOLD" -lt 1 ] || [ "$MEMORY_THRESHOLD" -gt 100 ]; then
            echo "Error: Memory threshold must be a number between 1 and 100" >&2
            return 1
        fi
    fi

    if ! echo "$SLEEP_TIME" | grep -Eq '^[0-9]+$' || [ "$SLEEP_TIME" -lt 1 ]; then
        echo "Error: Sleep time must be a positive number" >&2
        return 1
    fi

    # Validate kill count if specified
    if [ -n "$KILL_COUNT" ]; then
        if ! echo "$KILL_COUNT" | grep -Eq '^[0-9]+$' || [ "$KILL_COUNT" -lt 1 ]; then
            echo "Error: Kill count must be a positive number" >&2
            return 1
        fi
        if [ "$AGGREGATE_MODE" -eq 0 ]; then
            echo "Error: Kill count (-k) can only be used with aggregate mode (-a)" >&2
            return 1
        fi
    fi

    # Validate time window if specified
    if [ -n "$TIME_WINDOW" ]; then
        # Parse violations/window format (e.g., 3/5)
        if echo "$TIME_WINDOW" | grep -Eq '^[0-9]+/[0-9]+$'; then
            VIOLATIONS_NEEDED=$(echo "$TIME_WINDOW" | cut -d'/' -f1)
            WINDOW_SIZE=$(echo "$TIME_WINDOW" | cut -d'/' -f2)
            
            if [ "$VIOLATIONS_NEEDED" -lt 1 ] || [ "$WINDOW_SIZE" -lt 1 ]; then
                echo "Error: Time window values must be positive numbers" >&2
                return 1
            fi
            
            if [ "$VIOLATIONS_NEEDED" -gt "$WINDOW_SIZE" ]; then
                echo "Error: Violations needed cannot exceed window size" >&2
                return 1
            fi
        else
            echo "Error: Time window must be in format X/Y (e.g., 3/5 for 3 violations in 5 checks)" >&2
            return 1
        fi
    fi

    # Check for required commands
    for cmd in ps awk kill bc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: Required command '$cmd' not found" >&2
            return 1
        fi
    done

    # Check if specified process exists before starting monitor
    if [ -n "$PROCESS_NAME" ]; then
        if ! ps aux | grep -v grep | grep -i "$PROCESS_NAME" >/dev/null 2>&1; then
            echo "Error: No process found matching '$PROCESS_NAME'" >&2
            echo "Please check the process name and try again." >&2
            return 1
        fi
    fi
    
    echo "Starting process monitor..."
    if [ "$MONITOR_CPU" -eq 1 ]; then
        echo "CPU Threshold: ${CPU_THRESHOLD}%"
    fi
    if [ "$MONITOR_MEM" -eq 1 ]; then
        echo "Memory Threshold: ${MEMORY_THRESHOLD}%"
    fi
    echo "Sleep interval: ${SLEEP_TIME}s"
    if [ -n "$PROCESS_NAME" ]; then
        echo "Monitoring process: $PROCESS_NAME"
    else
        echo "Monitoring all processes"
    fi
    if [ "$TEST_MODE" -eq 1 ]; then
        echo "TEST MODE: No processes will be killed"
    fi
    if [ "$AGGREGATE_MODE" -eq 1 ]; then
        echo "AGGREGATE MODE: Monitoring combined usage"
        if [ -n "$KILL_COUNT" ]; then
            echo "Kill count: $KILL_COUNT processes per threshold breach"
        else
            echo "Kill strategy: Kill until under threshold"
        fi
    else
        echo "INDIVIDUAL MODE: Monitoring each process separately"
    fi
    if [ -n "$TIME_WINDOW" ]; then
        echo "TIME WINDOW: Kill after $VIOLATIONS_NEEDED violations within $WINDOW_SIZE checks"
    else
        echo "TIME WINDOW: Disabled (kill on first violation)"
    fi
    echo "Press Ctrl+C to stop"
    echo "----------------------------------------"

    # Set up signal handling for graceful shutdown
    trap 'echo ""; echo "Monitoring stopped."; return 0' INT TERM

    # Initialize violation tracking
    # Format: PID:CHECK1,CHECK2,... stored in VIOLATION_HISTORY
    VIOLATION_HISTORY=""
    CHECK_COUNT=0

    # Function to add a violation for a process
    add_violation() {
        pid="$1"
        new_history=""
        found=0

        # Heredoc, not pipe: keeps the loop in this shell so new_history/found
        # persist (POSIX sh and bash run pipe-RHS in a subshell).
        while IFS=':' read -r vpid vchecks; do
            if [ -n "$vpid" ]; then
                if [ "$vpid" = "$pid" ]; then
                    new_history="${new_history}${pid}:${vchecks},${CHECK_COUNT}
"
                    found=1
                else
                    new_history="${new_history}${vpid}:${vchecks}
"
                fi
            fi
        done <<EOF
$VIOLATION_HISTORY
EOF

        if [ "$found" -eq 0 ]; then
            new_history="${new_history}${pid}:${CHECK_COUNT}
"
        fi

        VIOLATION_HISTORY="$new_history"
    }

    # Function to count recent violations for a process
    count_violations() {
        pid="$1"
        count=0

        if [ -z "$WINDOW_SIZE" ]; then
            # No time window - any violation counts
            echo "$VIOLATION_HISTORY" | grep "^${pid}:" >/dev/null && echo "1" || echo "0"
            return
        fi

        # Count violations within window
        min_check=$((CHECK_COUNT - WINDOW_SIZE + 1))
        [ "$min_check" -lt 1 ] && min_check=1

        vchecks=$(echo "$VIOLATION_HISTORY" | grep "^${pid}:" | cut -d':' -f2)
        # Walk comma-list via parameter expansion: portable across sh/bash/zsh
        # (zsh does not field-split $var by default).
        remaining="$vchecks"
        while [ -n "$remaining" ]; do
            case "$remaining" in
                *,*) check="${remaining%%,*}"; remaining="${remaining#*,}" ;;
                *)   check="$remaining"; remaining="" ;;
            esac
            if [ -n "$check" ] && [ "$check" -ge "$min_check" ]; then
                count=$((count + 1))
            fi
        done
        echo "$count"
    }

    # Function to clean old violations outside window
    clean_old_violations() {
        if [ -z "$WINDOW_SIZE" ]; then
            return
        fi

        min_check=$((CHECK_COUNT - WINDOW_SIZE + 1))
        [ "$min_check" -lt 1 ] && min_check=1

        new_history=""
        while IFS=':' read -r vpid vchecks; do
            if [ -n "$vpid" ]; then
                new_checks=""
                remaining="$vchecks"
                while [ -n "$remaining" ]; do
                    case "$remaining" in
                        *,*) check="${remaining%%,*}"; remaining="${remaining#*,}" ;;
                        *)   check="$remaining"; remaining="" ;;
                    esac
                    if [ -n "$check" ] && [ "$check" -ge "$min_check" ]; then
                        [ -n "$new_checks" ] && new_checks="${new_checks},"
                        new_checks="${new_checks}${check}"
                    fi
                done

                if [ -n "$new_checks" ]; then
                    new_history="${new_history}${vpid}:${new_checks}
"
                fi
            fi
        done <<EOF
$VIOLATION_HISTORY
EOF

        VIOLATION_HISTORY="$new_history"
    }

    # Main monitoring loop
    while true; do
        # Increment check counter
        CHECK_COUNT=$((CHECK_COUNT + 1))
        
        # Clean old violations outside window
        clean_old_violations
        
        # Get all process information with CPU and memory usage (single ps call)
        # ps aux format: USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
        
        # Cache process data for this iteration
        if [ -n "$PROCESS_NAME" ]; then
            ALL_PROCESSES=$(ps aux | grep -v grep | grep -i "$PROCESS_NAME")
        else
            ALL_PROCESSES=$(ps aux | awk 'NR > 1')  # Skip header
        fi
        
        if [ "$AGGREGATE_MODE" -eq 1 ]; then
            # AGGREGATE MODE: Check combined usage against thresholds
            if [ -n "$ALL_PROCESSES" ]; then
                # Calculate aggregate usage
                total_cpu=$(echo "$ALL_PROCESSES" | awk '{sum += $3} END {printf "%.1f", sum}')
                total_mem=$(echo "$ALL_PROCESSES" | awk '{sum += $4} END {printf "%.1f", sum}')
                process_count=$(echo "$ALL_PROCESSES" | wc -l | tr -d ' ')
                
                # Check if aggregate usage exceeds thresholds
                threshold_exceeded=0
                exceeded_reasons=""
                
                if [ "$MONITOR_CPU" -eq 1 ] && [ "$(echo "$total_cpu > $CPU_THRESHOLD" | bc 2>/dev/null)" = "1" ] 2>/dev/null; then
                    threshold_exceeded=1
                    exceeded_reasons="CPU=${total_cpu}%"
                fi
                
                if [ "$MONITOR_MEM" -eq 1 ] && [ "$(echo "$total_mem > $MEMORY_THRESHOLD" | bc 2>/dev/null)" = "1" ] 2>/dev/null; then
                    threshold_exceeded=1
                    if [ -n "$exceeded_reasons" ]; then
                        exceeded_reasons="${exceeded_reasons}, MEM=${total_mem}%"
                    else
                        exceeded_reasons="MEM=${total_mem}%"
                    fi
                fi
                
                if [ "$threshold_exceeded" -eq 1 ]; then
                    # Determine target name for display
                    if [ -n "$PROCESS_NAME" ]; then
                        target_name="$PROCESS_NAME"
                    else
                        target_name="all processes"
                    fi
                    
                    # Use "AGGREGATE" as the PID for aggregate violations
                    add_violation "AGGREGATE"
                    violation_count=$(count_violations "AGGREGATE")
                    
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - Aggregate threshold exceeded:"
                    printf "  Target: %s (%d instances) CPU: %s%% Memory: %s%% - %s\n" "$target_name" "$process_count" "$total_cpu" "$total_mem" "$exceeded_reasons"
                    
                    # Check if we should kill based on time window
                    should_kill=0
                    if [ -n "$TIME_WINDOW" ]; then
                        if [ "$violation_count" -ge "$VIOLATIONS_NEEDED" ]; then
                            echo "  -> Violation $violation_count of $VIOLATIONS_NEEDED within $WINDOW_SIZE checks"
                            should_kill=1
                        else
                            echo "  -> Violation $violation_count of $VIOLATIONS_NEEDED within $WINDOW_SIZE checks (not killing yet)"
                        fi
                    else
                        should_kill=1
                    fi
                    
                    if [ "$should_kill" -eq 1 ]; then
                        # Sort processes by the metric that exceeded the threshold (or by highest usage)
                        if [ "$MONITOR_CPU" -eq 1 ] && echo "$exceeded_reasons" | grep -q "CPU"; then
                            # Sort by CPU (descending)
                            SORTED_PROCESSES=$(echo "$ALL_PROCESSES" | awk '{
                                cmd = ""; for(i=11; i<=NF; i++) cmd = cmd $i " ";
                                printf "%s %s %.1f %.1f %s\n", $1, $2, $3, $4, cmd
                            }' | sort -k3 -nr)
                        else
                            # Sort by Memory (descending)
                            SORTED_PROCESSES=$(echo "$ALL_PROCESSES" | awk '{
                                cmd = ""; for(i=11; i<=NF; i++) cmd = cmd $i " ";
                                printf "%s %s %.1f %.1f %s\n", $1, $2, $3, $4, cmd
                            }' | sort -k4 -nr)
                        fi
                        
                        # Determine how many processes to kill
                        if [ -n "$KILL_COUNT" ]; then
                            processes_to_kill="$KILL_COUNT"
                        else
                            # Kill until under threshold - start with 1 and check if more needed
                            processes_to_kill=1
                        fi
                        
                        # Kill the specified number of processes
                        killed_count=0
                        echo "$SORTED_PROCESSES" | while IFS=' ' read -r user pid cpu mem cmd && [ "$killed_count" -lt "$processes_to_kill" ]; do
                            # Extract app name for display
                            if [ -n "$PROCESS_NAME" ]; then
                                app_name="$PROCESS_NAME"
                            else
                                app_name=$(echo "$cmd" | awk -F'/' '{print $NF}' | awk '{print $1}')
                            fi
                            
                            if [ "$TEST_MODE" -eq 1 ]; then
                                printf "    -> Would kill PID %s (%s) CPU: %.1f%% Memory: %.1f%% [TEST MODE]\n" "$pid" "$app_name" "$cpu" "$mem"
                            else
                                if kill -TERM "$pid" 2>/dev/null; then
                                    printf "    -> Killed PID %s (%s) CPU: %.1f%% Memory: %.1f%%\n" "$pid" "$app_name" "$cpu" "$mem"
                                else
                                    printf "    -> Failed to kill PID %s (%s) (may require sudo)\n" "$pid" "$app_name"
                                fi
                            fi
                            killed_count=$((killed_count + 1))
                        done
                        
                        # Clear aggregate violation history after killing
                        if [ -n "$TIME_WINDOW" ] && [ "$TEST_MODE" -eq 0 ]; then
                            VIOLATION_HISTORY=$(echo "$VIOLATION_HISTORY" | grep -v "^AGGREGATE:")
                        fi
                    fi
                    echo ""
                else
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - Aggregate usage within thresholds"
                    if [ -n "$PROCESS_NAME" ]; then
                        printf "  Target: %s (%d instances) CPU: %s%% Memory: %s%%\n" "$PROCESS_NAME" "$process_count" "$total_cpu" "$total_mem"
                    else
                        printf "  All processes: CPU: %s%% Memory: %s%%\n" "$total_cpu" "$total_mem"
                    fi
                fi
            else
                if [ -n "$PROCESS_NAME" ]; then
                    echo "Warning: Process '$PROCESS_NAME' no longer exists. Exiting monitor." >&2
                    return 1
                else
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - No processes found"
                fi
            fi
        else
            # INDIVIDUAL MODE: Check each process separately (original logic)
            # Build awk condition based on what we're monitoring
            AWK_CONDITION=""
            if [ "$MONITOR_CPU" -eq 1 ] && [ "$MONITOR_MEM" -eq 1 ]; then
                AWK_CONDITION='$3 > cpu || $4 > mem'
            elif [ "$MONITOR_CPU" -eq 1 ]; then
                AWK_CONDITION='$3 > cpu'
            elif [ "$MONITOR_MEM" -eq 1 ]; then
                AWK_CONDITION='$4 > mem'
            fi
            
            # Find processes exceeding thresholds
            PROCESSES=$(echo "$ALL_PROCESSES" | awk -v cpu="${CPU_THRESHOLD:-999}" -v mem="${MEMORY_THRESHOLD:-999}" "
                $AWK_CONDITION {
                    cmd = \"\"; for(i=11; i<=NF; i++) cmd = cmd \$i \" \";
                    printf \"%s %s %.1f %.1f %s\\n\", \$1, \$2, \$3, \$4, cmd
                }
            ")
            
            if [ -n "$PROCESSES" ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Found processes exceeding thresholds:"
                echo "$PROCESSES" | while IFS=' ' read -r user pid cpu mem cmd; do
                    reason=""
                    if [ "$MONITOR_CPU" -eq 1 ] && [ "$(echo "$cpu > $CPU_THRESHOLD" | bc 2>/dev/null)" = "1" ] 2>/dev/null; then
                        reason="CPU=${cpu}%"
                    fi
                    if [ "$MONITOR_MEM" -eq 1 ] && [ "$(echo "$mem > $MEMORY_THRESHOLD" | bc 2>/dev/null)" = "1" ] 2>/dev/null; then
                        if [ -n "$reason" ]; then
                            reason="${reason}, MEM=${mem}%"
                        else
                            reason="MEM=${mem}%"
                        fi
                    fi
                    
                    # Extract just the app name
                    if [ -n "$PROCESS_NAME" ]; then
                        app_name="$PROCESS_NAME"
                    else
                        # Try to extract app name from command for all processes mode
                        app_name=$(echo "$cmd" | awk -F'/' '{print $NF}' | awk '{print $1}')
                    fi
                    
                    printf "  Process: %s CPU: %.1f%% Memory: %.1f%%\n" "$app_name" "$cpu" "$mem"
                    
                    # Add violation to history
                    add_violation "$pid"
                    
                    # Check if process has enough violations
                    violation_count=$(count_violations "$pid")
                    
                    if [ -n "$TIME_WINDOW" ]; then
                        # Time window mode - check if enough violations
                        if [ "$violation_count" -ge "$VIOLATIONS_NEEDED" ]; then
                            echo "    -> Violation $violation_count of $VIOLATIONS_NEEDED within $WINDOW_SIZE checks"
                            if [ "$TEST_MODE" -eq 1 ]; then
                                echo "    -> Would kill PID $pid ($reason) [TEST MODE]"
                            else
                                if kill -TERM "$pid" 2>/dev/null; then
                                    echo "    -> Killed PID $pid ($reason)"
                                    # Remove from violation history after killing
                                    VIOLATION_HISTORY=$(echo "$VIOLATION_HISTORY" | grep -v "^${pid}:")
                                else
                                    echo "    -> Failed to kill PID $pid (may require sudo)"
                                fi
                            fi
                        else
                            echo "    -> Violation $violation_count of $VIOLATIONS_NEEDED within $WINDOW_SIZE checks (not killing yet)"
                        fi
                    else
                        # No time window - kill immediately
                        if [ "$TEST_MODE" -eq 1 ]; then
                            echo "    -> Would kill PID $pid ($reason) [TEST MODE]"
                        else
                            if kill -TERM "$pid" 2>/dev/null; then
                                echo "    -> Killed PID $pid ($reason)"
                            else
                                echo "    -> Failed to kill PID $pid (may require sudo)"
                            fi
                        fi
                    fi
                done
                echo ""
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - No individual processes exceeding thresholds"
                
                # Show status of monitored processes using cached data
                if [ -n "$ALL_PROCESSES" ]; then
                    # Filter processes for display
                    if [ "$COMPACT_MODE" -eq 1 ]; then
                        # Only show processes with CPU >= 1% or Memory >= 1%
                        STATUS_PROCESSES=$(echo "$ALL_PROCESSES" | awk -v min_cpu="$MIN_CPU_DISPLAY" -v min_mem="$MIN_MEM_DISPLAY" '
                            $3 >= min_cpu || $4 >= min_mem {
                                cmd = ""; for(i=11; i<=NF; i++) cmd = cmd $i " ";
                                printf "%s %s %.1f %.1f %s\n", $1, $2, $3, $4, cmd
                            }
                        ')
                    else
                        # Show all processes
                        STATUS_PROCESSES=$(echo "$ALL_PROCESSES" | awk '
                            {
                                cmd = ""; for(i=11; i<=NF; i++) cmd = cmd $i " ";
                                printf "%s %s %.1f %.1f %s\n", $1, $2, $3, $4, cmd
                            }
                        ')
                    fi
                    
                    if [ -n "$STATUS_PROCESSES" ]; then
                        if [ "$COMPACT_MODE" -eq 1 ]; then
                            echo "Current status (active processes only):"
                        else
                            echo "Current status of monitored processes:"
                        fi
                        
                        echo "$STATUS_PROCESSES" | while IFS=' ' read -r user pid cpu mem cmd; do
                            # Extract just the app name from the full command
                            if [ -n "$PROCESS_NAME" ]; then
                                app_name="$PROCESS_NAME"
                            else
                                app_name=$(echo "$cmd" | awk -F'/' '{print $NF}' | awk '{print $1}')
                            fi
                            printf "  Process: %s CPU: %.1f%% Memory: %.1f%%\n" "$app_name" "$cpu" "$mem"
                        done
                    else
                        if [ "$COMPACT_MODE" -eq 1 ]; then
                            echo "No active processes found (all below 1% CPU and 1% Memory)"
                        elif [ -n "$PROCESS_NAME" ]; then
                            echo "Warning: Process '$PROCESS_NAME' no longer exists. Exiting monitor." >&2
                            return 1
                        fi
                    fi
                fi
            fi
        fi
        
        sleep "$SLEEP_TIME"
    done
}
