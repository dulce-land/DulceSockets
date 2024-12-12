
import CDulceSockets

func dulce_socket_start(){
  #if os(Windows)
    var mi_data : WSADATA

    WSAStartup(MAKEWORD(2, 2), &mi_data)
  #endif

}

func dulce_socket_stop(){

  #if os(Windows)
    WSACleanup();
  #endif

}
