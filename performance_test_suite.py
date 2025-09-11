#!/usr/bin/env python3
"""
KBNT Virtual Stock Service - Performance & Stress Testing Suite
=============================================================

Comprehensive performance testing for the virtual stock service including:
- Load Testing (normal usage simulation)
- Stress Testing (beyond normal capacity)
- Spike Testing (sudden load increases)
- Volume Testing (large data operations)

Author: KBNT Performance Team
Date: September 2025
"""

import asyncio
import aiohttp
import json
import time
import statistics
import sys
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
import threading
import random
import uuid

class PerformanceTestSuite:
    def __init__(self, base_url="http://172.30.221.62:8084"):
        self.base_url = base_url
        self.api_endpoint = f"{base_url}/api/v1/virtual-stock/stocks"
        self.results = {
            "test_timestamp": datetime.now().isoformat(),
            "environment": {
                "base_url": base_url,
                "test_suite_version": "1.0.0"
            },
            "tests": {}
        }
        
    def generate_test_stock(self, test_id=""):
        """Generate random stock data for testing"""
        symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "META", "NVDA", "NFLX"]
        return {
            "symbol": f"{random.choice(symbols)}{test_id}",
            "productName": f"Test Stock {test_id} {random.choice(['Inc', 'Corp', 'LLC'])}",
            "quantity": random.randint(10, 1000),
            "unitPrice": round(random.uniform(10.0, 500.0), 2),
            "productId": f"TEST-{test_id}-{uuid.uuid4().hex[:8]}"
        }

    async def single_request_test(self, session, test_data):
        """Execute a single API request and measure performance"""
        start_time = time.time()
        try:
            async with session.post(self.api_endpoint, json=test_data) as response:
                response_time = time.time() - start_time
                status = response.status
                content = await response.text()
                
                return {
                    "success": status == 201,
                    "status_code": status,
                    "response_time": response_time,
                    "content_length": len(content)
                }
        except Exception as e:
            return {
                "success": False,
                "status_code": 0,
                "response_time": time.time() - start_time,
                "error": str(e)
            }

    async def load_test(self, concurrent_users=10, requests_per_user=10):
        """Load Testing: Simulate normal usage patterns"""
        print(f"\n🔄 LOAD TEST: {concurrent_users} concurrent users, {requests_per_user} requests each")
        
        async with aiohttp.ClientSession() as session:
            # Health check first
            try:
                async with session.get(f"{self.base_url}/actuator/health") as response:
                    if response.status != 200:
                        print("❌ Service health check failed!")
                        return None
            except Exception as e:
                print(f"❌ Cannot connect to service: {e}")
                return None
            
            tasks = []
            test_start = time.time()
            
            # Create concurrent user tasks
            for user_id in range(concurrent_users):
                for req_id in range(requests_per_user):
                    test_data = self.generate_test_stock(f"L{user_id}R{req_id}")
                    task = self.single_request_test(session, test_data)
                    tasks.append(task)
            
            # Execute all requests concurrently
            results = await asyncio.gather(*tasks, return_exceptions=True)
            test_duration = time.time() - test_start
            
            # Analyze results
            successful_requests = [r for r in results if isinstance(r, dict) and r.get("success")]
            failed_requests = [r for r in results if isinstance(r, dict) and not r.get("success")]
            error_requests = [r for r in results if isinstance(r, Exception)]
            
            response_times = [r["response_time"] for r in successful_requests]
            
            test_results = {
                "test_type": "load_test",
                "configuration": {
                    "concurrent_users": concurrent_users,
                    "requests_per_user": requests_per_user,
                    "total_requests": len(tasks)
                },
                "execution": {
                    "test_duration": round(test_duration, 3),
                    "requests_per_second": round(len(tasks) / test_duration, 2)
                },
                "results": {
                    "total_requests": len(tasks),
                    "successful_requests": len(successful_requests),
                    "failed_requests": len(failed_requests),
                    "error_requests": len(error_requests),
                    "success_rate": round((len(successful_requests) / len(tasks)) * 100, 2)
                },
                "performance_metrics": {
                    "avg_response_time": round(statistics.mean(response_times) if response_times else 0, 3),
                    "min_response_time": round(min(response_times) if response_times else 0, 3),
                    "max_response_time": round(max(response_times) if response_times else 0, 3),
                    "p50_response_time": round(statistics.median(response_times) if response_times else 0, 3),
                    "p95_response_time": round(self.percentile(response_times, 95) if response_times else 0, 3),
                    "p99_response_time": round(self.percentile(response_times, 99) if response_times else 0, 3)
                }
            }
            
            print(f"✅ Load Test Complete: {test_results['results']['success_rate']}% success rate")
            print(f"📊 Avg Response Time: {test_results['performance_metrics']['avg_response_time']}s")
            print(f"🚀 Requests/Second: {test_results['execution']['requests_per_second']}")
            
            return test_results

    async def stress_test(self, max_users=50, ramp_up_time=30):
        """Stress Testing: Push beyond normal capacity"""
        print(f"\n💪 STRESS TEST: Ramping up to {max_users} users over {ramp_up_time}s")
        
        stress_results = []
        
        for current_users in range(5, max_users + 1, 5):
            print(f"🔄 Testing with {current_users} concurrent users...")
            
            result = await self.load_test(concurrent_users=current_users, requests_per_user=5)
            if result:
                stress_results.append({
                    "concurrent_users": current_users,
                    "success_rate": result["results"]["success_rate"],
                    "avg_response_time": result["performance_metrics"]["avg_response_time"],
                    "requests_per_second": result["execution"]["requests_per_second"]
                })
                
                # Stop if success rate drops below 90%
                if result["results"]["success_rate"] < 90:
                    print(f"⚠️ Success rate dropped to {result['results']['success_rate']}% - stopping stress test")
                    break
            
            await asyncio.sleep(2)  # Brief pause between stress levels
        
        test_results = {
            "test_type": "stress_test",
            "configuration": {
                "max_users_tested": max_users,
                "ramp_up_time": ramp_up_time
            },
            "stress_levels": stress_results,
            "breaking_point": self.find_breaking_point(stress_results)
        }
        
        print(f"💥 Stress Test Complete. Breaking point: {test_results['breaking_point']['users']} users")
        return test_results

    async def spike_test(self, normal_load=10, spike_load=100, spike_duration=10):
        """Spike Testing: Sudden load increases"""
        print(f"\n⚡ SPIKE TEST: {normal_load} → {spike_load} users for {spike_duration}s")
        
        # Normal load phase
        print("📊 Phase 1: Normal load baseline")
        normal_result = await self.load_test(concurrent_users=normal_load, requests_per_user=5)
        
        await asyncio.sleep(2)
        
        # Spike phase
        print("🚀 Phase 2: Spike load")
        spike_start = time.time()
        spike_result = await self.load_test(concurrent_users=spike_load, requests_per_user=3)
        spike_actual_duration = time.time() - spike_start
        
        await asyncio.sleep(2)
        
        # Recovery phase
        print("📈 Phase 3: Recovery to normal load")
        recovery_result = await self.load_test(concurrent_users=normal_load, requests_per_user=5)
        
        test_results = {
            "test_type": "spike_test",
            "configuration": {
                "normal_load": normal_load,
                "spike_load": spike_load,
                "target_spike_duration": spike_duration,
                "actual_spike_duration": round(spike_actual_duration, 2)
            },
            "phases": {
                "normal_baseline": normal_result["performance_metrics"] if normal_result else None,
                "spike_load": spike_result["performance_metrics"] if spike_result else None,
                "recovery": recovery_result["performance_metrics"] if recovery_result else None
            },
            "spike_impact": {
                "performance_degradation": self.calculate_degradation(normal_result, spike_result),
                "recovery_successful": self.check_recovery(normal_result, recovery_result)
            }
        }
        
        print(f"⚡ Spike Test Complete. Performance degradation: {test_results['spike_impact']['performance_degradation']}%")
        return test_results

    async def volume_test(self, batch_size=100):
        """Volume Testing: Large batch operations"""
        print(f"\n📦 VOLUME TEST: Creating {batch_size} stocks in batch")
        
        start_time = time.time()
        
        async with aiohttp.ClientSession() as session:
            tasks = []
            for i in range(batch_size):
                test_data = self.generate_test_stock(f"VOL{i}")
                task = self.single_request_test(session, test_data)
                tasks.append(task)
            
            results = await asyncio.gather(*tasks, return_exceptions=True)
            test_duration = time.time() - start_time
            
            successful_requests = [r for r in results if isinstance(r, dict) and r.get("success")]
            
            test_results = {
                "test_type": "volume_test",
                "configuration": {
                    "batch_size": batch_size
                },
                "execution": {
                    "test_duration": round(test_duration, 3),
                    "throughput": round(len(successful_requests) / test_duration, 2)
                },
                "results": {
                    "total_requests": len(tasks),
                    "successful_requests": len(successful_requests),
                    "success_rate": round((len(successful_requests) / len(tasks)) * 100, 2)
                }
            }
            
            print(f"📦 Volume Test Complete: {test_results['results']['success_rate']}% success rate")
            print(f"🚀 Throughput: {test_results['execution']['throughput']} requests/second")
            
            return test_results

    def percentile(self, data, percent):
        """Calculate percentile of a dataset"""
        if not data:
            return 0
        data_sorted = sorted(data)
        k = (len(data_sorted) - 1) * (percent / 100)
        f = int(k)
        c = k - f
        if f == len(data_sorted) - 1:
            return data_sorted[f]
        return data_sorted[f] * (1 - c) + data_sorted[f + 1] * c

    def find_breaking_point(self, stress_results):
        """Find the breaking point in stress test results"""
        for result in stress_results:
            if result["success_rate"] < 95:
                return {
                    "users": result["concurrent_users"],
                    "success_rate": result["success_rate"],
                    "avg_response_time": result["avg_response_time"]
                }
        return {
            "users": stress_results[-1]["concurrent_users"] if stress_results else 0,
            "success_rate": stress_results[-1]["success_rate"] if stress_results else 0,
            "avg_response_time": stress_results[-1]["avg_response_time"] if stress_results else 0
        }

    def calculate_degradation(self, normal_result, spike_result):
        """Calculate performance degradation during spike"""
        if not normal_result or not spike_result:
            return 0
        
        normal_time = normal_result["performance_metrics"]["avg_response_time"]
        spike_time = spike_result["performance_metrics"]["avg_response_time"]
        
        if normal_time == 0:
            return 0
            
        return round(((spike_time - normal_time) / normal_time) * 100, 2)

    def check_recovery(self, normal_result, recovery_result):
        """Check if system recovered after spike"""
        if not normal_result or not recovery_result:
            return False
        
        normal_time = normal_result["performance_metrics"]["avg_response_time"]
        recovery_time = recovery_result["performance_metrics"]["avg_response_time"]
        
        # Consider recovered if within 20% of original performance
        return abs(recovery_time - normal_time) / normal_time <= 0.2

    async def run_full_test_suite(self):
        """Run complete performance test suite"""
        print("🚀 KBNT Virtual Stock Service - Performance Test Suite")
        print("=" * 60)
        
        # 1. Load Test
        load_result = await self.load_test(concurrent_users=20, requests_per_user=10)
        if load_result:
            self.results["tests"]["load_test"] = load_result
        
        await asyncio.sleep(5)
        
        # 2. Stress Test
        stress_result = await self.stress_test(max_users=50, ramp_up_time=30)
        if stress_result:
            self.results["tests"]["stress_test"] = stress_result
        
        await asyncio.sleep(5)
        
        # 3. Spike Test
        spike_result = await self.spike_test(normal_load=15, spike_load=75, spike_duration=10)
        if spike_result:
            self.results["tests"]["spike_test"] = spike_result
        
        await asyncio.sleep(5)
        
        # 4. Volume Test
        volume_result = await self.volume_test(batch_size=200)
        if volume_result:
            self.results["tests"]["volume_test"] = volume_result
        
        return self.results

    def generate_summary_report(self):
        """Generate executive summary of test results"""
        if not self.results.get("tests"):
            return "No test results available"
        
        summary = {
            "overall_status": "PASS",
            "key_metrics": {},
            "recommendations": []
        }
        
        # Analyze load test
        if "load_test" in self.results["tests"]:
            load = self.results["tests"]["load_test"]
            summary["key_metrics"]["load_test_success_rate"] = load["results"]["success_rate"]
            summary["key_metrics"]["avg_response_time"] = load["performance_metrics"]["avg_response_time"]
            summary["key_metrics"]["requests_per_second"] = load["execution"]["requests_per_second"]
            
            if load["results"]["success_rate"] < 95:
                summary["overall_status"] = "FAIL"
                summary["recommendations"].append("Load test success rate below 95%")
        
        # Analyze stress test
        if "stress_test" in self.results["tests"]:
            stress = self.results["tests"]["stress_test"]
            breaking_point = stress["breaking_point"]["users"]
            summary["key_metrics"]["max_concurrent_users"] = breaking_point
            
            if breaking_point < 30:
                summary["recommendations"].append("Low concurrent user capacity")
        
        # Analyze spike test
        if "spike_test" in self.results["tests"]:
            spike = self.results["tests"]["spike_test"]
            degradation = spike["spike_impact"]["performance_degradation"]
            recovery = spike["spike_impact"]["recovery_successful"]
            
            summary["key_metrics"]["spike_degradation"] = degradation
            summary["key_metrics"]["spike_recovery"] = recovery
            
            if degradation > 200:
                summary["recommendations"].append("High performance degradation during spikes")
            if not recovery:
                summary["recommendations"].append("System did not recover well after spike")
        
        return summary

    def save_results(self, filename=None):
        """Save test results to JSON file"""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"performance_test_results_{timestamp}.json"
        
        with open(filename, 'w') as f:
            json.dump(self.results, f, indent=2)
        
        return filename

async def main():
    """Main execution function"""
    print("🔧 Initializing KBNT Performance Test Suite...")
    
    # Check if service is reachable
    test_suite = PerformanceTestSuite()
    
    try:
        # Run full test suite
        results = await test_suite.run_full_test_suite()
        
        # Generate summary
        summary = test_suite.generate_summary_report()
        
        # Save results
        results_file = test_suite.save_results()
        
        print("\n" + "=" * 60)
        print("📊 PERFORMANCE TEST SUITE COMPLETED")
        print("=" * 60)
        print(f"📁 Results saved to: {results_file}")
        print(f"🎯 Overall Status: {summary['overall_status']}")
        print(f"✅ Load Test Success Rate: {summary['key_metrics'].get('load_test_success_rate', 'N/A')}%")
        print(f"⚡ Average Response Time: {summary['key_metrics'].get('avg_response_time', 'N/A')}s")
        print(f"🚀 Requests/Second: {summary['key_metrics'].get('requests_per_second', 'N/A')}")
        print(f"👥 Max Concurrent Users: {summary['key_metrics'].get('max_concurrent_users', 'N/A')}")
        
        if summary.get("recommendations"):
            print("\n⚠️ Recommendations:")
            for rec in summary["recommendations"]:
                print(f"   • {rec}")
        
        return results_file
        
    except KeyboardInterrupt:
        print("\n⏹️ Test suite interrupted by user")
        return None
    except Exception as e:
        print(f"\n❌ Test suite failed: {e}")
        return None

if __name__ == "__main__":
    # Run the performance test suite
    asyncio.run(main())
