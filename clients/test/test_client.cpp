#include "rhubarbClient.h"

const int ERROR = -1;
const int OK = 0;

#define START_TEST(x) std::cout << x << "... ";
#define RETURN_ERROR(x) { std::cerr << x << std::endl; return ERROR; }
#define RETURN_ERROR_ELSE_OK(x) RETURN_ERROR(x) else { std::cout << "OK" << std::endl; }

#define DO_TEST(desc, cond, err_msg) \
    START_TEST(desc); \
    if(cond) RETURN_ERROR_ELSE_OK(err_msg);

int main(int argc, char** argv)
{
    rhubarbClient client("127.0.0.1", 1234);

    std::string motd("");

    DO_TEST("Check connection", !client.doConnect(&motd), "Unable to connect to server.");
    
    std::string expected_motd("Welcome to BelugaServer, client ");

    DO_TEST("Check MOTD",
            expected_motd.compare(0, expected_motd.size(), motd, 0, expected_motd.size()) != 0,
            "Obtained motd \"" << motd << "\" does not match expected.");

    std::string expected_ping_response("PONG!");
    std::string ping_response = client.doMessage("ping");
    DO_TEST("Check ping response",
            expected_ping_response.compare(ping_response),
            "Unexpected ping response \"" << ping_response << "\".");

    std::cout << std::endl << "\tAll tests pass!" << std::endl;
    
    return OK;
}
