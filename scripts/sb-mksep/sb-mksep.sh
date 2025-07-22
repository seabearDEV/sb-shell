#!/bin/sh

# sb-mksep.sh - Monitor and Kill System Exhausting Processes
# Description: Monitors processes and kills them when they exceed CPU or memory thresholds
# Usage: sb-mksep [-n PROCESS_NAME] [-c CPU_THRESHOLD] [-m MEMORY_THRESHOLD] [-s SLEEP_TIME] [-t] [-o] [-a] [-k KILL_COUNT]
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
#   -h                  Show help

# Function to monitor and kill system exhausting processes
sb-mksep() {
    # Default values
    local PROCESS_NAME=""
    local CPU_THRESHOLD=""
    local MEMORY_THRESHOLD=""
    local SLEEP_TIME=30
    local TEST_MODE=0
    local MONITOR_CPU=0
    local MONITOR_MEM=0
    local COMPACT_MODE=0
    local AGGREGATE_MODE=0
    local MIN_CPU_DISPLAY=0
    local MIN_MEM_DISPLAY=0
    local KILL_COUNT=""

    # Display usage information
    usage() {
        cat << EOF
Usage: sb-mksep [-n PROCESS_NAME] [-c CPU_THRESHOLD] [-m MEMORY_THRESHOLD] [-s SLEEP_TIME] [-t] [-o] [-a] [-k KILL_COUNT] [-h]

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
  -h                  Show this help message

Modes:
  Individual mode (default): Each process checked separately against thresholds
  Aggregate mode (-a): Combined usage of matching processes checked against thresholds

Examples:
  sb-mksep -n firefox -c 90 -m 85    Monitor firefox, kill individual processes if CPU>90% or Memory>85%
  sb-mksep -n chrome -a -c 80         Aggregate mode: kill Chrome processes when combined CPU>80%
  sb-mksep -a -m 90 -k 2              Kill 2 highest memory processes when total system memory>90%
  sb-mksep -c 95 -t                   Test mode: monitor all processes, show if any exceed 95% CPU
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
    while getopts ":n:c:m:s:k:toah" opt; do
        case $opt in
            n) PROCESS_NAME="$OPTARG" ;;
            c) CPU_THRESHOLD="$OPTARG"; MONITOR_CPU=1 ;;
            m) MEMORY_THRESHOLD="$OPTARG"; MONITOR_MEM=1 ;;
            s) SLEEP_TIME="$OPTARG" ;;
            k) KILL_COUNT="$OPTARG" ;;
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
    echo "Press Ctrl+C to stop"
    echo "----------------------------------------"

    # Set up signal handling for graceful shutdown
    trap 'echo ""; echo "Monitoring stopped."; return 0' INT TERM

    # Main monitoring loop
    while true; do
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
                    
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - Aggregate threshold exceeded:"
                    printf "  Target: %s (%d instances) CPU: %s%% Memory: %s%% - %s\n" "$target_name" "$process_count" "$total_cpu" "$total_mem" "$exceeded_reasons"
                    
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
                    
                    if [ "$TEST_MODE" -eq 1 ]; then
                        echo "    -> Would kill PID $pid ($reason) [TEST MODE]"
                    else
                        if kill -TERM "$pid" 2>/dev/null; then
                            echo "    -> Killed PID $pid ($reason)"
                        else
                            echo "    -> Failed to kill PID $pid (may require sudo)"
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
