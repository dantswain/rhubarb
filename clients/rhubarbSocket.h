#ifndef CP_SOCKET
#define CP_SOCKET

/*
 *  rhubarbSocket.h - functions for connecting to rhubarb
 *  servers via c++
 *
 *  Compiling:  Shouldn't require anything other than including
 *  this header.  Requires a c++ compiler.
 *
 *  Should actually be relatively applicapble to any client
 *  connection that transfers line-by-line
 *
 *  Copyright (c) 2011 Daniel T. Swain
 *  See the file license.txt for copying permissions
 *
 */

#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#include <string.h>

#include <iostream>
#include <sstream>

typedef int rhubarb_socket_t;

std::string recvRhubarbLine(rhubarb_socket_t sock, int buff_size = 1024)
{
    std::ostringstream ss;
    char buffer[buff_size];

    int nread = 0;
    int d = 0;
    char lastchar = 0;
    do
    {
        memset(buffer, 0, sizeof(buffer));

        d = recv(sock, buffer, buff_size, 0);
        if(d > 0)
        {
            nread += d;
            ss << buffer;
            lastchar = buffer[d-1];
        }
        
    } while(nread < buff_size && d >= 0 && lastchar != 10);

    std::string result = ss.str();
    result = result.substr(0, result.length()-1);
    return result;
    
}

int sendRhubarbLine(rhubarb_socket_t sock, const char* line)
{
    std::string _line(line);
    if(line[strlen(line)] != '\n')
    {
        _line += "\n";
    }
    return send(sock, _line.c_str(), _line.length(), 0);
}

std::string rhubarbMessage(rhubarb_socket_t sock, const char* message)
{
    sendRhubarbLine(sock, message);
    return recvRhubarbLine(sock);
}

rhubarb_socket_t getRhubarbSocket(const char* hostname,
                                  int port,
                                  std::string* message = NULL)
{
    struct sockaddr_in sa;
    struct hostent* server;

    server = gethostbyname(hostname);
    if(!server)
    {
        std::cerr << "Unable to determine hostname\n";
        return -1;
    } 

    memset(&sa, 0, sizeof(sa));

    sa.sin_family = AF_INET;
    bcopy((char *) server->h_addr,
          (char *) &sa.sin_addr.s_addr,
          server->h_length);
    sa.sin_port = htons(port);

    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if(sock < 0)
    {
        std::cerr << "Unable to create socket\n";
        return -1;
    }

    if(connect(sock, (struct sockaddr*) &sa, sizeof(sa)) < 0)
    {
        std::cerr << "Unable to connect to server " << hostname
                  << ":" << port << std::endl;
        return -1;
    }

    std::string motd = recvRhubarbLine(sock);
    if(message)
    {
        *message = motd;
    }

    return sock;
}

void closeRhubarbSocket(rhubarb_socket_t sock)
{
    close(sock);
}

#endif // CP_SOCKET
