#ifdef __linux__
#define EPOLL
#elif defined(__APPLE__)
#define KQUEUE
#endif

#define HTTPSERVER_IMPL
#include "./include/httpserver.h"
