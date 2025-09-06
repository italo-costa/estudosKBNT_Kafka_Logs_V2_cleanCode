
import socket
import threading
import time

class MockKafkaServer:
    def __init__(self, port=9092):
        self.port = port
        self.running = False
        
    def start(self):
        self.running = True
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(('localhost', self.port))
        server.listen(5)
        
        print(f"Target Kafka server listening on localhost:{self.port}")
        
        while self.running:
            try:
                client, addr = server.accept()
                print(f"Connection from {addr}")
                client.send(b"Kafka-like server\n")
                client.close()
            except:
                break
                
        server.close()

if __name__ == "__main__":
    server = MockKafkaServer()
    try:
        server.start()
    except KeyboardInterrupt:
        print("\nStopping mock Kafka server...")
        server.running = False
