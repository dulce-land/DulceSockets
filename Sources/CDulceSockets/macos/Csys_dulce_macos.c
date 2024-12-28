
#include "Csys_dulce_macos.h"

#include <stddef.h>
#include <string.h>
#include <errno.h>

void c_show_error(
    char message[],
    int *len)
{

    const char *msg_tmp = strerror(errno);

    const int msg_tmp_length = strlen(msg_tmp);

    *len = (msg_tmp_length < *len ? msg_tmp_length : *len);

    memcpy(message, msg_tmp, (size_t)*len);
}
