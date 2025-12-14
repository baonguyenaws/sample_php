#!/usr/bin/env python3
"""
Memory Load Generator - Configurable memory usage via environment variable
Supports: 75%, 85%, 99% memory targets
"""
import psutil
import time
import os
from datetime import datetime

class MemoryLoadGenerator:
    def __init__(self, target_percentage=75):
        """
        Initialize Memory Load Generator
        
        Args:
            target_percentage: Target memory usage percentage (default 75%)
        """
        self.target_percentage = target_percentage
        self.data_blocks = []
        self.block_size = 10 * 1024 * 1024  # 10 MB per block
        
    def get_container_memory_limit(self):
        """Get container memory limit from cgroup"""
        try:
            # Try cgroup v2 first
            if os.path.exists('/sys/fs/cgroup/memory.max'):
                with open('/sys/fs/cgroup/memory.max', 'r') as f:
                    limit = f.read().strip()
                    if limit != 'max':
                        return int(limit)
            
            # Try cgroup v1
            if os.path.exists('/sys/fs/cgroup/memory/memory.limit_in_bytes'):
                with open('/sys/fs/cgroup/memory/memory.limit_in_bytes', 'r') as f:
                    limit = int(f.read().strip())
                    # If limit is very large, it means no limit set
                    if limit < (1 << 60):  # Less than ~1 exabyte
                        return limit
        except Exception as e:
            print(f"[{datetime.now()}] Warning: Could not read cgroup limit: {e}")
        
        return None
    
    def get_container_memory_usage(self):
        """Get actual memory usage of container from cgroup"""
        try:
            # Try cgroup v2 first
            if os.path.exists('/sys/fs/cgroup/memory.current'):
                with open('/sys/fs/cgroup/memory.current', 'r') as f:
                    return int(f.read().strip())
            
            # Try cgroup v1
            if os.path.exists('/sys/fs/cgroup/memory/memory.usage_in_bytes'):
                with open('/sys/fs/cgroup/memory/memory.usage_in_bytes', 'r') as f:
                    return int(f.read().strip())
        except Exception as e:
            print(f"[{datetime.now()}] Warning: Could not read cgroup usage: {e}")
        
        return None
    
    def get_memory_info(self):
        """Get current system memory information"""
        mem = psutil.virtual_memory()
        
        # Check if running in container with memory limit
        container_limit = self.get_container_memory_limit()
        
        if container_limit:
            # Get actual container memory usage
            container_usage = self.get_container_memory_usage()
            
            if container_usage:
                used = container_usage
                available = container_limit - used
                percent = (used / container_limit) * 100
            else:
                # Fallback to psutil if cgroup usage not available
                used = mem.used
                available = container_limit - used
                percent = (used / container_limit) * 100
            
            return {
                'total': container_limit,
                'available': max(0, available),
                'percent': percent,
                'used': used,
                'free': max(0, available),
                'is_container': True
            }
        else:
            # Use host memory
            return {
                'total': mem.total,
                'available': mem.available,
                'percent': mem.percent,
                'used': mem.used,
                'free': mem.free,
                'is_container': False
            }
    
    def format_bytes(self, bytes_value):
        """Format bytes to human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_value < 1024.0:
                return f"{bytes_value:.2f} {unit}"
            bytes_value /= 1024.0
        return f"{bytes_value:.2f} PB"
    
    def calculate_target_memory(self):
        """Calculate target memory to allocate"""
        mem_info = self.get_memory_info()
        total_memory = mem_info['total']
        target_memory = int(total_memory * self.target_percentage / 100)
        
        print(f"[{datetime.now()}] ===== Memory Information =====")
        if mem_info.get('is_container'):
            print(f"[{datetime.now()}] Running in: CONTAINER (with memory limit)")
        else:
            print(f"[{datetime.now()}] Running in: HOST (no container limit)")
        print(f"[{datetime.now()}] Total Memory: {self.format_bytes(total_memory)}")
        print(f"[{datetime.now()}] Available Memory: {self.format_bytes(mem_info['available'])}")
        print(f"[{datetime.now()}] Current Usage: {mem_info['percent']:.2f}%")
        print(f"[{datetime.now()}] Target Percentage: {self.target_percentage}%")
        print(f"[{datetime.now()}] Target Memory to Allocate: {self.format_bytes(target_memory)}")
        print(f"[{datetime.now()}] =====================================")
        
        return target_memory
    
    def allocate_memory(self, target_memory):
        """
        Allocate memory to reach target usage
        
        Args:
            target_memory: Target memory in bytes to allocate
        """
        print(f"[{datetime.now()}] Starting memory allocation...")
        
        allocated = 0
        block_count = 0
        
        try:
            while allocated < target_memory:
                # Calculate remaining memory to allocate
                remaining = target_memory - allocated
                
                # Adjust block size if needed
                if remaining < self.block_size:
                    current_block_size = remaining
                else:
                    current_block_size = self.block_size
                
                # Allocate memory block (fill with data to ensure physical allocation)
                block = bytearray(current_block_size)
                # Fill with pattern to ensure memory is actually used
                for i in range(0, len(block), 1024):
                    block[i] = i % 256
                
                self.data_blocks.append(block)
                allocated += current_block_size
                block_count += 1
                
                # Log progress every 100MB
                if block_count % 10 == 0:
                    current_mem = self.get_memory_info()
                    print(f"[{datetime.now()}] Allocated: {self.format_bytes(allocated)} "
                          f"({block_count} blocks) | "
                          f"Current Memory Usage: {current_mem['percent']:.2f}%")
                
                # Small delay to prevent overwhelming the system
                time.sleep(0.01)
                
        except MemoryError:
            print(f"[{datetime.now()}] MemoryError: Cannot allocate more memory")
            print(f"[{datetime.now()}] Successfully allocated: {self.format_bytes(allocated)}")
        
        return allocated
    
    def monitor_memory(self, interval=5):
        """
        Monitor memory usage periodically
        
        Args:
            interval: Monitoring interval in seconds
        """
        print(f"\n[{datetime.now()}] ===== Memory Monitoring Started =====")
        print(f"[{datetime.now()}] Monitoring interval: {interval} seconds")
        print(f"[{datetime.now()}] Press Ctrl+C to stop\n")
        
        try:
            while True:
                mem_info = self.get_memory_info()
                print(f"[{datetime.now()}] Memory Usage: {mem_info['percent']:.2f}% | "
                      f"Used: {self.format_bytes(mem_info['used'])} / "
                      f"Total: {self.format_bytes(mem_info['total'])} | "
                      f"Available: {self.format_bytes(mem_info['available'])}")
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print(f"\n[{datetime.now()}] Monitoring stopped by user")
    
    def run(self):
        """Main execution function"""
        print(f"[{datetime.now()}] ===== Memory Load Generator Started =====")
        print(f"[{datetime.now()}] PID: {os.getpid()}")
        print(f"[{datetime.now()}] Target: {self.target_percentage}% Memory utilization\n")
        
        # Calculate target memory
        target_memory = self.calculate_target_memory()
        
        # Get current memory usage
        current_mem = self.get_memory_info()
        current_usage_bytes = current_mem['used']
        
        # Calculate how much more we need to allocate
        to_allocate = target_memory - current_usage_bytes
        
        if to_allocate <= 0:
            print(f"[{datetime.now()}] Current memory usage ({current_mem['percent']:.2f}%) "
                  f"already meets or exceeds target ({self.target_percentage}%)")
            print(f"[{datetime.now()}] No additional allocation needed")
        else:
            print(f"[{datetime.now()}] Need to allocate: {self.format_bytes(to_allocate)}\n")
            
            # Allocate memory
            allocated = self.allocate_memory(to_allocate)
            
            # Show final status
            final_mem = self.get_memory_info()
            print(f"\n[{datetime.now()}] ===== Allocation Complete =====")
            print(f"[{datetime.now()}] Allocated: {self.format_bytes(allocated)}")
            print(f"[{datetime.now()}] Number of blocks: {len(self.data_blocks)}")
            print(f"[{datetime.now()}] Final Memory Usage: {final_mem['percent']:.2f}%")
            print(f"[{datetime.now()}] Used: {self.format_bytes(final_mem['used'])} / "
                  f"Total: {self.format_bytes(final_mem['total'])}")
            print(f"[{datetime.now()}] =====================================\n")
        
        # Start monitoring
        self.monitor_memory(interval=10)

def main():
    """Main function"""
    # Get target memory percentage from environment variable (default: 100%)
    target_percentage = int(os.getenv('MEMORY_TARGET', '100'))
    
    # Create and run memory load generator
    generator = MemoryLoadGenerator(target_percentage=target_percentage)
    generator.run()

if __name__ == "__main__":
    main()
