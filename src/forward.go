package main

import (
	"fmt"
	"io"
	"net"
	"os"
)

func main() {
	localPort := os.Args[1]

	ln, err := net.Listen("tcp", fmt.Sprintf(":%s", localPort))
	if err != nil {
		panic(err)
	}

	for {
		conn, err := ln.Accept()
		if err != nil {
			panic(err)
		}

		go handleRequest(conn)
	}
}

func handleRequest(conn net.Conn) {
	remoteService := os.Args[2]
	proxy, err := net.Dial("tcp", remoteService)
	if err != nil {
		panic(err)
	}

	go copyIO(conn, proxy)
	go copyIO(proxy, conn)
}

func copyIO(src, dest net.Conn) {
	defer src.Close()
	defer dest.Close()
	io.Copy(src, dest)
}
