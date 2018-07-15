#include <muduo/net/TcpServer.h>

#include <muduo/base/Atomic.h>
#include <muduo/base/Logging.h>
#include <muduo/base/Thread.h>
#include <muduo/net/EventLoop.h>
#include <muduo/net/InetAddress.h>

#include <boost/bind.hpp>

#include <utility>

#include <stdio.h>
#include <unistd.h>
#include <iostream>

using namespace muduo;
using namespace muduo::net;

void onConnection(const TcpConnectionPtr& conn) {
    if (conn->connected()) {
        conn->setTcpNoDelay(true);
    }
}

void onMessage(const TcpConnectionPtr& conn, Buffer* buf, Timestamp) {
    conn->send(buf);
}

int main(int argc, char* argv[]) {
    LOG_INFO << "pid = " << getpid() << ", tid = " << CurrentThread::tid();
    Logger::setLogLevel(Logger::INFO);

    const string ip = "0.0.0.0";
    const uint16_t port = 9099;
    InetAddress listenAddr(ip, port);
    int threadCount = 4;

    EventLoop loop;

    TcpServer server(&loop, listenAddr, "PingPong");

    server.setConnectionCallback(onConnection);
    server.setMessageCallback(onMessage);

    if (threadCount > 1)
    {
        server.setThreadNum(threadCount);
    }

    server.start();

    loop.loop();
}