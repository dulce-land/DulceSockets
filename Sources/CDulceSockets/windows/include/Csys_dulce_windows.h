

#include <winsock2.h>
#include <ws2tcpip.h>

typedef SOCKET Dulce_Socket_Descriptor;

static const Dulce_Socket_Descriptor C_Socket_Invalid = INVALID_SOCKET;

static const Dulce_Socket_Descriptor C_Socket_Error = SOCKET_ERROR;

static const int c_sock_dgram = SOCK_DGRAM;
static const int c_sock_stream = SOCK_STREAM;

void c_show_error(
    char message[],
    int *len);

void c_reuse_address(Dulce_Socket_Descriptor fd);
