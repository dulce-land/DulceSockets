
#ifdef _WIN32

#include "Csys_dulce_windows.h"

void c_show_error(
    char message[],
    int *len)
{

    int err = WSAGetLastError();

    char msg_tmp[256]; // for a message up to 255 bytes.
    msg_tmp[0] = '\0'; // Microsoft doesn't guarantee this on man page.

    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM |
                      FORMAT_MESSAGE_IGNORE_INSERTS,         // flags
                  NULL,                                      // lpsource
                  err,                                       // message id
                  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // languageid
                  msg_tmp,                                   // output buffer
                  sizeof(msg_tmp),                           // size of msgbuf, bytes
                  NULL);                                     // va_list of arguments

    if (!*msg_tmp)
        sprintf(msg_tmp, "%d", err); // provide error # if no string available

    const int msg_tmp_length = strlen(msg_tmp);

    *len = (msg_tmp_length < *len ? msg_tmp_length : *len);

    memcpy(message, msg_tmp, (size_t)*len);
}

void c_reuse_address(Dulce_Socket_Descriptor fd)
{
    char optval = '1';

    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof optval);
}

struct sockaddr_in c_to_ipv4_address(const struct sockaddr *from)
{
    struct sockaddr_in mi_val = *((struct sockaddr_in *)from);
    return mi_val;
}

struct sockaddr_in6 c_to_ipv6_address(const struct sockaddr *from)
{
    struct sockaddr_in6 mi_val = *((struct sockaddr_in6 *)from);
    return mi_val;
}

struct sockaddr_storage c_to_ipany_address(const struct sockaddr *from)
{
    struct sockaddr_storage mi_val = *((struct sockaddr_storage *)from);
    return mi_val;
}

struct sockaddr c_from_ipv4_address(const struct sockaddr_in *from)
{
    struct sockaddr mi_val = *((struct sockaddr *)from);
    return mi_val;
}

struct sockaddr c_from_ipv6_address(const struct sockaddr_in6 *from)
{
    struct sockaddr mi_val = *((struct sockaddr *)from);
    return mi_val;
}

struct sockaddr c_from_ipany_address(const struct sockaddr_storage *from)
{
    struct sockaddr mi_val = *((struct sockaddr *)from);
    return mi_val;
}

#endif
