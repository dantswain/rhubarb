/*
 *  sample_client.cpp - shows simple usage of rhubarb client socket
 *
 *  compiling:
 *     *nix/OS X:  g++ sample_client.cpp -o sample_client
 *  
 *  Copyright (c) 2011 Daniel T. Swain
 *  See the file license.txt for copying permissions
 *
 */


#include <stdio.h>

#include "clients/rhubarbSocket.h"

int main(int argc, char** argv)
{

    rhubarb_socket_t sock = getRhubarbSocket("127.0.0.1", 1234);

    std::cout << "Got:  " << rhubarbMessage(sock, "get ultimateanswer") << std::endl;
    std::cout << "Got:  " << rhubarbMessage(sock, "set ultimateanswer 54") << std::endl;    
    
    closeRhubarbSocket(sock);

}
