
import CDulceSockets

public func dulce_Socket_Start(){
  #if os(Windows)
    var mi_data : WSADATA

    WSAStartup(MAKEWORD(2, 2), &mi_data)
  #endif

}

public func dulce_Socket_Stop(){

  #if os(Windows)
    WSACleanup();
  #endif

}
