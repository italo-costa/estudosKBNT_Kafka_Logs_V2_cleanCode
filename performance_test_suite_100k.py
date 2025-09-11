#!/usr/bin/env python3
"""
KBNT Virtual Stock Service - High Load Performance Testing Suite (100K)
=======================================================================

Ultra-high performance testing for 100,000+ requests with:
- Massive Load Testing (100K requests)
- Extreme Stress Testing (progressive load to breaking point)
- Resource monitoring and optimization
- Batch processing for memory efficiency

Author: KBNT Performance Team
Date: September 2025
"""

import asyncio
import aiohttp
import json
import time
import statistics
import sys
import gc
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
import threading
import random
import uuid
import psutil
import os

class HighLoadPerformanceTestSuite:
    def __init__(self, base_url="http://172.30.221.62:8084"):
        self.base_url = base_url
        self.api_endpoint = f"{base_url}/api/v1/virtual-stock/stocks"
        self.session = None
        self.results = {
            "test_timestamp": datetime.now().isoformat(),
            "environment": {
                "base_url": base_url,
                "test_suite_version": "2.0.0-100K",
                "system_info": self._get_system_info()
            },
            "tests": {}
        }
        
    def _get_system_info(self):
        """Get system information for performance context"""
        try:
            return {
                "cpu_count": psutil.cpu_count(),
                "memory_total_gb": round(psutil.virtual_memory().total / (1024**3), 2),
                "python_version": sys.version.split()[0]
            }
        except:
            return {"info": "System info not available"}
        
    def generate_test_stock(self, test_id=""):
        """Generate random stock data for testing - optimized for high volume"""
        symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "META", "NVDA", "NFLX", "ORCL", "CRM"]
        return {
            "symbol": f"{random.choice(symbols)}{test_id % 1000}",  # Reuse symbols to reduce memory
            "productName": f"Stock-{test_id}",
            "quantity": random.randint(10, 1000),
            "unitPrice": round(random.uniform(10.0, 500.0), 2),
            "productId": f"BULK-{test_id}"
        }

    async def create_session(self):
        """Create optimized HTTP session for high load"""
        connector = aiohttp.TCPConnector(
            limit=1000,  # Increased connection pool
            limit_per_host=500,
            ttl_dns_cache=300,
            use_dns_cache=True,
            keepalive_timeout=30,
            enable_cleanup_closed=True
        )
        timeout = aiohttp.ClientTimeout(total=60, connect=10)
        self.session = aiohttp.ClientSession(
            connector=connector,
            timeout=timeout,
            headers={"Content-Type": "application/json"}
        )

    async def close_session(self):
        """Properly close HTTP session"""
        if self.session:
            await self.session.close()

    async def make_request(self, stock_data, semaphore):
        """Make single HTTP request with semaphore control"""
        async with semaphore:
            try:
                async with self.session.post(self.api_endpoint, json=stock_data) as response:
                    if response.status == 201:
                        return {"success": True, "status": response.status, "response_time": 0}
                    else:
                        return {"success": False, "status": response.status, "response_time": 0}
            except Exception as e:
                return {"success": False, "error": str(e), "response_time": 0}

    async def batch_load_test(self, total_requests=100000, concurrent_limit=200, batch_size=1000):
        """
        Perform high-load test with 100K requests in batches
        """
        print(f"\n🚀 HIGH LOAD TEST: {total_requests:,} requests, {concurrent_limit} concurrent limit")
        
        if not self.session:
            await self.create_session()
            
        semaphore = asyncio.Semaphore(concurrent_limit)
        
        # Track metrics
        successful_requests = 0
        failed_requests = 0
        response_times = []
        start_time = time.time()
        
        # Process in batches to manage memory
        batches = total_requests // batch_size
        remaining = total_requests % batch_size
        
        print(f"📊 Processing {batches} batches of {batch_size} + {remaining} remaining requests")
        
        for batch_num in range(batches + (1 if remaining > 0 else 0)):
            current_batch_size = batch_size if batch_num < batches else remaining
            if current_batch_size == 0:
                continue
                
            print(f"🔄 Batch {batch_num + 1}/{batches + (1 if remaining > 0 else 0)} - {current_batch_size} requests")
            
            # Create batch tasks
            batch_start = time.time()
            tasks = []
            
            for i in range(current_batch_size):
                request_id = batch_num * batch_size + i
                stock_data = self.generate_test_stock(request_id)
                task = self.make_request(stock_data, semaphore)
                tasks.append(task)
            
            # Execute batch
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)
            batch_time = time.time() - batch_start
            
            # Process results
            batch_success = 0
            batch_failed = 0
            
            for result in batch_results:
                if isinstance(result, dict) and result.get("success"):
                    batch_success += 1
                    successful_requests += 1
                else:
                    batch_failed += 1
                    failed_requests += 1
            
            batch_rps = current_batch_size / batch_time if batch_time > 0 else 0
            print(f"✅ Batch {batch_num + 1} complete: {batch_success}/{current_batch_size} success, {batch_rps:.2f} req/s")
            
            # Memory cleanup
            del tasks, batch_results
            gc.collect()
            
            # Brief pause between batches to prevent overwhelming
            if batch_num < batches - 1:
                await asyncio.sleep(0.1)
        
        total_time = time.time() - start_time
        overall_rps = total_requests / total_time if total_time > 0 else 0
        success_rate = (successful_requests / total_requests) * 100 if total_requests > 0 else 0
        
        results = {
            "test_type": "high_load_test_100k",
            "configuration": {
                "total_requests": total_requests,
                "concurrent_limit": concurrent_limit,
                "batch_size": batch_size
            },
            "execution": {
                "total_duration": round(total_time, 3),
                "requests_per_second": round(overall_rps, 2)
            },
            "results": {
                "total_requests": total_requests,
                "successful_requests": successful_requests,
                "failed_requests": failed_requests,
                "success_rate": round(success_rate, 2)
            },
            "performance_metrics": {
                "avg_response_time": "N/A (batch processing)",
                "total_throughput": round(overall_rps, 2),
                "memory_efficient": True
            }
        }
        
        print(f"\n🎯 HIGH LOAD TEST COMPLETE:")
        print(f"✅ Success Rate: {success_rate:.2f}% ({successful_requests:,}/{total_requests:,})")
        print(f"🚀 Overall Throughput: {overall_rps:.2f} requests/second")
        print(f"⏱️ Total Duration: {total_time:.2f} seconds")
        
        return results

    async def progressive_stress_test(self, max_users=1000, step=50, duration_per_step=30):
        """
        Progressive stress test ramping up to extreme loads
        """
        print(f"\n💪 PROGRESSIVE STRESS TEST: Up to {max_users} concurrent users")
        
        if not self.session:
            await self.create_session()
        
        stress_levels = []
        breaking_point = None
        
        for current_users in range(step, max_users + 1, step):
            print(f"🔄 Testing with {current_users} concurrent users...")
            
            semaphore = asyncio.Semaphore(current_users)
            start_time = time.time()
            
            # Run for specified duration
            successful = 0
            failed = 0
            total_requests = 0
            
            end_time = start_time + duration_per_step
            
            while time.time() < end_time:
                # Create batch of requests
                tasks = []
                batch_size = min(current_users, 100)  # Limit batch size
                
                for i in range(batch_size):
                    stock_data = self.generate_test_stock(total_requests + i)
                    tasks.append(self.make_request(stock_data, semaphore))
                
                try:
                    results = await asyncio.gather(*tasks, return_exceptions=True)
                    
                    for result in results:
                        total_requests += 1
                        if isinstance(result, dict) and result.get("success"):
                            successful += 1
                        else:
                            failed += 1
                            
                except Exception as e:
                    failed += len(tasks)
                    total_requests += len(tasks)
                
                # Brief pause
                await asyncio.sleep(0.01)
            
            actual_duration = time.time() - start_time
            success_rate = (successful / total_requests) * 100 if total_requests > 0 else 0
            rps = total_requests / actual_duration if actual_duration > 0 else 0
            
            level_result = {
                "concurrent_users": current_users,
                "duration": round(actual_duration, 2),
                "total_requests": total_requests,
                "successful_requests": successful,
                "failed_requests": failed,
                "success_rate": round(success_rate, 2),
                "requests_per_second": round(rps, 2)
            }
            
            stress_levels.append(level_result)
            
            print(f"📊 {current_users} users: {success_rate:.1f}% success, {rps:.1f} req/s")
            
            # Check if this is breaking point
            if success_rate < 95:  # Consider 95% success rate as threshold
                breaking_point = {
                    "users": current_users,
                    "success_rate": success_rate,
                    "requests_per_second": rps
                }
                print(f"💥 Breaking point detected at {current_users} users!")
                break
        
        return {
            "test_type": "progressive_stress_test",
            "configuration": {
                "max_users_tested": max_users,
                "step_size": step,
                "duration_per_step": duration_per_step
            },
            "stress_levels": stress_levels,
            "breaking_point": breaking_point or {
                "users": f"{max_users}+",
                "note": "No breaking point found within test limits"
            }
        }

    async def run_comprehensive_100k_test(self):
        """Run comprehensive 100K request test suite"""
        print("🔥 KBNT Virtual Stock Service - 100K High Load Performance Test Suite")
        print("=" * 80)
        
        try:
            await self.create_session()
            
            # Test 1: 100K Load Test
            load_test_result = await self.batch_load_test(
                total_requests=100000,
                concurrent_limit=200,
                batch_size=1000
            )
            self.results["tests"]["load_test_100k"] = load_test_result
            
            # Test 2: Progressive Stress Test
            stress_test_result = await self.progressive_stress_test(
                max_users=500,
                step=25,
                duration_per_step=20
            )
            self.results["tests"]["progressive_stress_test"] = stress_test_result
            
            # Test 3: Extreme Spike Test (50K requests in 30 seconds)
            print(f"\n⚡ EXTREME SPIKE TEST: 50K requests in 30 seconds")
            spike_result = await self.batch_load_test(
                total_requests=50000,
                concurrent_limit=500,
                batch_size=2000
            )
            self.results["tests"]["extreme_spike_test"] = spike_result
            
        finally:
            await self.close_session()
        
        # Save results
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"performance_test_results_100k_{timestamp}.json"
        
        with open(filename, 'w') as f:
            json.dump(self.results, f, indent=2)
        
        # Print summary
        print("\n" + "=" * 80)
        print("🎯 100K PERFORMANCE TEST SUITE COMPLETED")
        print("=" * 80)
        print(f"📁 Results saved to: {filename}")
        
        # Extract key metrics
        load_test = self.results["tests"]["load_test_100k"]
        stress_test = self.results["tests"]["progressive_stress_test"]
        spike_test = self.results["tests"]["extreme_spike_test"]
        
        print(f"🎯 100K Load Test: {load_test['results']['success_rate']}% success")
        print(f"🚀 Throughput: {load_test['performance_metrics']['total_throughput']} req/s")
        print(f"💪 Stress Breaking Point: {stress_test['breaking_point']['users']} users")
        print(f"⚡ Spike Test: {spike_test['results']['success_rate']}% success")
        
        return filename

async def main():
    """Main execution function"""
    suite = HighLoadPerformanceTestSuite()
    
    try:
        result_file = await suite.run_comprehensive_100k_test()
        print(f"\n✅ Test completed successfully! Results in: {result_file}")
        return result_file
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    # Check if psutil is available
    try:
        import psutil
    except ImportError:
        print("⚠️ psutil not found. Install with: pip install psutil")
        print("Continuing without system monitoring...")
    
    # Run the test
    result = asyncio.run(main())
    if result:
        print(f"\n🎉 100K Performance Test Suite completed successfully!")
        print(f"📊 Results file: {result}")
    else:
        print("\n💥 Test suite failed!")
        sys.exit(1)
