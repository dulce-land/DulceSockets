
#ifdef __linux__

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <poll.h>
#include <unistd.h>


typedef int Dulce_Socket_Descriptor;

static const Dulce_Socket_Descriptor C_Socket_Invalid = -1;

static const Dulce_Socket_Descriptor C_Socket_Error = -1;

static const int c_sock_dgram = SOCK_DGRAM;
static const int c_sock_stream = SOCK_STREAM;

void c_show_error(
    char message[],
    int *len);

void c_reuse_address(Dulce_Socket_Descriptor fd);

#endif
