#!/usr/bin/env python3
"""
CPU Load Generator - Configurable CPU usage via environment variable
Supports: 75%, 85%, 99% CPU targets
"""
import multiprocessing
import time
import os
from datetime import datetime

def cpu_load_worker(target_load=1.0, duration=None):
    """
    Worker function that generates CPU load
    
    Args:
        target_load: Target load for this worker (0.0 to 1.0, where 1.0 = 100%)
        duration: Optional duration in seconds
    """
    print(f"[{datetime.now()}] Worker {os.getpid()} started (target load: {target_load*100:.0f}%)")
    start_time = time.time()
    
    if target_load >= 0.99:
        # If target is ~100%, just run continuously
        while True:
            for i in range(10000):
                _ = i ** 2
            
            if duration and (time.time() - start_time) > duration:
                break
    else:
        # For partial load, use busy-wait cycle
        # busy_time / (busy_time + sleep_time) = target_load
        cycle_time = 0.1  # 100ms cycle
        busy_time = cycle_time * target_load
        sleep_time = cycle_time * (1 - target_load)
        
        while True:
            # Busy period
            busy_start = time.time()
            while (time.time() - busy_start) < busy_time:
                for i in range(1000):
                    _ = i ** 2
            
            # Sleep period
            if sleep_time > 0:
                time.sleep(sleep_time)
            
            if duration and (time.time() - start_time) > duration:
                break

def get_container_cpu_quota():
    """Get container CPU quota from cgroup"""
    try:
        # Try cgroup v2 first
        if os.path.exists('/sys/fs/cgroup/cpu.max'):
            with open('/sys/fs/cgroup/cpu.max', 'r') as f:
                content = f.read().strip().split()
                if content[0] != 'max':
                    quota = int(content[0])
                    period = int(content[1])
                    return quota / period
        
        # Try cgroup v1
        quota_file = '/sys/fs/cgroup/cpu/cpu.cfs_quota_us'
        period_file = '/sys/fs/cgroup/cpu/cpu.cfs_period_us'
        
        if os.path.exists(quota_file) and os.path.exists(period_file):
            with open(quota_file, 'r') as f:
                quota = int(f.read().strip())
            with open(period_file, 'r') as f:
                period = int(f.read().strip())
            
            if quota > 0:  # -1 means no limit
                return quota / period
    except Exception as e:
        print(f"[{datetime.now()}] Warning: Could not read cgroup CPU quota: {e}")
    
    return None

def get_cpu_count():
    """Get the number of CPU cores available (considering container limits)"""
    # Check if running in container with CPU limit
    container_cpu_quota = get_container_cpu_quota()
    
    if container_cpu_quota:
        # Use container CPU quota
        cpu_count = container_cpu_quota
        print(f"[{datetime.now()}] Running in: CONTAINER (with CPU limit)")
        print(f"[{datetime.now()}] Container CPU quota: {cpu_count:.2f} cores")
    else:
        # Use host CPU count
        cpu_count = multiprocessing.cpu_count()
        print(f"[{datetime.now()}] Running in: HOST (no container limit)")
        print(f"[{datetime.now()}] Detected {cpu_count} CPU cores")
    
    return cpu_count

def calculate_target_processes(cpu_count, target_percentage=85):
    """
    Calculate how many processes to spawn for target CPU usage
    
    Args:
        cpu_count: Number of CPU cores (can be fractional for containers)
        target_percentage: Target CPU usage percentage (default 85%)
    
    Returns:
        Number of processes to spawn
    """
    # Calculate target processes based on percentage
    # For fractional CPUs (e.g., 1.0 core with 85% target = 0.85 processes, round to 1)
    target_processes_float = cpu_count * target_percentage / 100
    target_processes = max(1, round(target_processes_float))
    
    print(f"[{datetime.now()}] Target CPU usage: {target_percentage}%")
    print(f"[{datetime.now()}] Target processes (calculated): {target_processes_float:.2f}")
    print(f"[{datetime.now()}] Spawning {target_processes} process(es) to achieve ~{target_percentage}% CPU load")
    
    return target_processes

def main():
    """Main function to start CPU load generator"""
    # Get target CPU percentage from environment variable (default: 85%)
    target_percentage = int(os.getenv('CPU_TARGET', '85'))
    
    # Validate target percentage
    if target_percentage not in [75, 85, 99]:
        print(f"[{datetime.now()}] Warning: CPU_TARGET={target_percentage} not in [75, 85, 99]. Using default 85%")
        target_percentage = 85
    
    print(f"[{datetime.now()}] ===== CPU Load Generator Started =====")
    print(f"[{datetime.now()}] Target: {target_percentage}% CPU utilization")
    
    # Get system CPU count (considering container limits)
    cpu_count = get_cpu_count()
    target_processes_float = cpu_count * target_percentage / 100
    target_processes = max(1, int(cpu_count))  # At least 1 full process
    
    # Calculate load per process
    if target_processes > 0:
        load_per_process = target_processes_float / target_processes
    else:
        load_per_process = target_percentage / 100
    
    print(f"[{datetime.now()}] Target CPU usage: {target_percentage}%")
    print(f"[{datetime.now()}] CPU count: {cpu_count:.2f}")
    print(f"[{datetime.now()}] Target load: {target_processes_float:.2f} cores")
    print(f"[{datetime.now()}] Spawning {target_processes} process(es)")
    print(f"[{datetime.now()}] Load per process: {load_per_process*100:.1f}%")
    
    # Create and start worker processes
    processes = []
    for i in range(target_processes):
        p = multiprocessing.Process(target=cpu_load_worker, args=(load_per_process,))
        p.start()
        processes.append(p)
        print(f"[{datetime.now()}] Started process {i+1}/{target_processes} (PID: {p.pid})")
    
    print(f"[{datetime.now()}] ===== All processes started successfully =====")
    print(f"[{datetime.now()}] Press Ctrl+C to stop")
    
    try:
        # Keep main process alive
        for p in processes:
            p.join()
    except KeyboardInterrupt:
        print(f"\n[{datetime.now()}] Stopping all processes...")
        for p in processes:
            p.terminate()
            p.join()
        print(f"[{datetime.now()}] All processes stopped")

if __name__ == "__main__":
    main()
