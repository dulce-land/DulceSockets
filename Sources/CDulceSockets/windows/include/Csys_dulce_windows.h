

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

struct sockaddr_in c_to_ipv4_address(const struct sockaddr *from);

struct sockaddr_in6 c_to_ipv6_address(const struct sockaddr *from);

struct sockaddr_storage c_to_ipany_address(const struct sockaddr *from);

struct sockaddr c_from_ipv4_address(const struct sockaddr_in *from);

struct sockaddr c_from_ipv6_address(const struct sockaddr_in6 *from);

struct sockaddr c_from_ipany_address(const struct sockaddr_storage *from);

