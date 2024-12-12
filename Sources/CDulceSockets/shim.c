#ifdef _WIN32

#include "Csys_dulce_windows.h"
#include "wepoll.h"

#elif __linux__

#include "Csys_dulce_linux.h"

#elif __APPLE__

#include "Csys_dulce_macos.h"

#elif __FreeBSD__

#include "Csys_dulce_macos.h"

#else

#include "Csys_dulce_linux.h"

#endif


