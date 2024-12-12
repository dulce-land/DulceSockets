// The Swift Programming Language
// https://docs.swift.org/swift-book

import CDulceSockets

enum Address {
  case ipv4 (sockaddr_in)
  case ipv6 (sockaddr_in6)
  case ipany (sockaddr_storage)
}

enum Address_Family {
  case ipv4
  case ipv6
  case ipany
}

enum Address_Type {
  case none
  case udp
  case tcp
  case other
}

struct Addresses {
  var addr_typ  : Address_Type  = .none
  var addr_arr  : [Address]     = []
}

struct Socket_Dulce {
  var sock : Dulce_Socket_Descriptor = 0
  var addr : Addresses  = Addresses()
  var binded    : Bool  = false
  var connected : Bool  = false
  var listened  : Bool  = false
}

func is_Initialized (sock: Socket_Dulce) -> Bool {
  return sock.sock > 0
}

func is_binded (sock: Socket_Dulce) -> Bool {
  return sock.binded
}

func is_listened (sock: Socket_Dulce) -> Bool {
  return sock.listened
}


func to_Number (from: Address_Family) -> Int32 {
  let mi_family  = switch from {
    case .ipany: AF_UNSPEC
    case .ipv6: AF_INET6
    case .ipv4: AF_INET
  }
  return mi_family
}

func to_Number (from: Address_Type) -> Int32 {
  let mi_address_type  = switch from {
    case .none: Int32(-1)
    case .tcp: c_sock_stream
    case .udp: c_sock_dgram
    case .other: Int32(-2)
  }
  return mi_address_type
}


func from_Number (from: Int32) -> Address_Family? {
  let mi_family : Address_Family? = switch from {
    case AF_UNSPEC: .ipany
    case AF_INET6:  .ipv6
    case AF_INET:   .ipv4
    default: nil
  }
  return mi_family
}

func from_Number (from: Int32) -> Address_Type? {
  let mi_address_type : Address_Type? = switch from {
    case Int32(-1): Address_Type.none
    case c_sock_stream: .tcp
    case c_sock_dgram:  .udp
    case Int32(-2): .other

    default: nil
  }
  return mi_address_type
}


func create_Address (host: String, port: String, address_family: Address_Family,
  address_type: Address_Type) -> Addresses?
{
  if address_type == .none || address_type == .other {
    return nil
  }

  var hints = addrinfo()

  hints.ai_flags = AI_PASSIVE
  hints.ai_family = to_Number(from: address_family)
  hints.ai_socktype = to_Number(from: address_type)
  hints.ai_protocol = 0
  hints.ai_addrlen  = 0
  hints.ai_canonname = nil // position change in os's
  hints.ai_addr = nil
  hints.ai_next = nil

  var servinfo: UnsafeMutablePointer<addrinfo>? = nil

  let addrInfoResult = getaddrinfo(
    host,
    port,                 // The port on which will be listenend
    &hints,               // Protocol configuration as per above
    &servinfo)

  if addrInfoResult != 0 {
    return nil
  }

  var mi_address = Addresses ()
  mi_address.addr_typ = address_type
  mi_address.addr_arr = []

  var mi_servinfo = servinfo

  repeat {

    if from_Number(from: mi_servinfo!.pointee.ai_family) == .ipv4 {
      let mi_tmp: sockaddr_in = c_to_ipv4_address(mi_servinfo!.pointee.ai_addr)
      mi_address.addr_arr.append (.ipv4 (mi_tmp))

    } else if from_Number(from: mi_servinfo!.pointee.ai_family) == .ipv6 {
      let mi_tmp: sockaddr_in6 = c_to_ipv6_address(mi_servinfo!.pointee.ai_addr)
      mi_address.addr_arr.append (.ipv6 (mi_tmp))

    } else if from_Number(from: mi_servinfo!.pointee.ai_family) == .ipany {
      let mi_tmp: sockaddr_storage = c_to_ipany_address(mi_servinfo!.pointee.ai_addr)
      mi_address.addr_arr.append (.ipany (mi_tmp))
    }

    mi_servinfo = mi_servinfo!.pointee.ai_next

  } while mi_servinfo != nil

  freeaddrinfo(servinfo)

  return mi_address
}


func create_Socket (from_address: Addresses, need_bind: Bool = false, need_listen: Bool = false,
  listen_backlog: UInt = 10) -> Socket_Dulce? {

  if from_address.addr_arr.count < 1 || from_address.addr_typ == .none || from_address.addr_typ == .other {
    return nil
  }

  var mi_socket = Socket_Dulce()

  mi_socket.addr.addr_typ = from_address.addr_typ
  mi_socket.addr.addr_arr = []

  let mi_type = to_Number(from: mi_socket.addr.addr_typ)

  var OK : Bool = false

  loop1_label:
  for mi_address in from_address.addr_arr {

    switch mi_address {

      case .ipv4(var addr):

        mi_socket.sock = socket(Int32 (addr.sin_family), mi_type, 0)

        if mi_socket.sock == C_Socket_Invalid {
          mi_socket.sock = 0
          OK = false
          continue loop1_label
        }

        mi_socket.addr.addr_arr.append(.ipv4(addr))

        OK = true

        if need_bind {
          c_reuse_address(mi_socket.sock)

          var addr_in_2 = c_from_ipv4_address(&addr)
          let mi_bind = bind (mi_socket.sock, &addr_in_2, socklen_t ((MemoryLayout<sockaddr_in>).stride))

          if mi_bind == C_Socket_Error {
            mi_socket.sock = 0
            mi_socket.addr.addr_arr = []
            OK = false
            continue loop1_label
          }

          mi_socket.binded = true

          OK = true

          if need_listen {

            if mi_socket.addr.addr_typ == .tcp {
              let mi_listen = listen(mi_socket.sock, Int32 (listen_backlog))

              if mi_listen == C_Socket_Error {
                mi_socket.sock = 0
                mi_socket.addr.addr_arr = []
                mi_socket.binded = false
                mi_socket.listened = false
                OK = false
                continue loop1_label
              }

              mi_socket.listened = true
              OK = true
            }

            if mi_socket.addr.addr_typ == .udp {
              mi_socket.listened = true
              OK = true
            }
          }
        }
        if OK {
          break loop1_label;
        }

      case .ipv6(var addr):

        mi_socket.sock = socket(Int32 (addr.sin6_family), mi_type, 0)

        if mi_socket.sock == C_Socket_Invalid {
          mi_socket.sock = 0
          OK = false
          continue loop1_label
        }

        mi_socket.addr.addr_arr.append(.ipv6(addr))

        OK = true

        if need_bind {
          c_reuse_address(mi_socket.sock)

          var addr_in_2 = c_from_ipv6_address(&addr)
          let mi_bind = bind (mi_socket.sock, &addr_in_2, socklen_t ((MemoryLayout<sockaddr_in6>).stride))

          if mi_bind == C_Socket_Error {
            mi_socket.sock = 0
            mi_socket.addr.addr_arr = []
            OK = false
            continue loop1_label
          }

          mi_socket.binded = true

          OK = true

          if need_listen {
            if mi_socket.addr.addr_typ == .tcp {
              let mi_listen = listen(mi_socket.sock, Int32 (listen_backlog))

              if mi_listen == C_Socket_Error {
                mi_socket.sock = 0
                mi_socket.addr.addr_arr = []
                mi_socket.binded = false
                mi_socket.listened = false
                OK = false
                continue loop1_label
              }

              mi_socket.listened = true
              OK = true
            }

            if mi_socket.addr.addr_typ == .udp {
              mi_socket.listened = true
              OK = true
            }
          }
        }
        if OK {
          break loop1_label;
        }


      case .ipany(var addr):

        mi_socket.sock = socket(Int32 (addr.ss_family), mi_type, 0)

        if mi_socket.sock == C_Socket_Invalid {
          mi_socket.sock = 0
          OK = false
          continue loop1_label
        }

        mi_socket.addr.addr_arr.append(.ipany(addr))

        OK = true

        if need_bind {
          c_reuse_address(mi_socket.sock)

          var addr_in_2 = c_from_ipany_address(&addr)
          let mi_bind = bind (mi_socket.sock, &addr_in_2, socklen_t ((MemoryLayout<sockaddr>).stride))

          if mi_bind == C_Socket_Error {
            mi_socket.sock = 0
            mi_socket.addr.addr_arr = []
            OK = false
            continue loop1_label
          }

          mi_socket.binded = true

          OK = true

          if need_listen {
            if mi_socket.addr.addr_typ == .tcp {
              let mi_listen = listen(mi_socket.sock, Int32 (listen_backlog))

              if mi_listen == C_Socket_Error {
                mi_socket.sock = 0
                mi_socket.addr.addr_arr = []
                mi_socket.binded = false
                mi_socket.listened = false
                OK = false
                continue loop1_label
              }

              mi_socket.listened = true
              OK = true
            }

            if mi_socket.addr.addr_typ == .udp {
              mi_socket.listened = true
              OK = true
            }
          }
        }
        if OK {
          break loop1_label;
        }

    }
  }

  if OK {
    return mi_socket
  }

  return nil
}

func get_Socket (sock: Socket_Dulce) -> Dulce_Socket_Descriptor {
  return sock.sock
}

func wait_connection (
  sock: Socket_Dulce,
  response: inout Socket_Dulce?,
  data_received: inout [UInt8],
  miliseconds_start_timeout: UInt32 = 0
) -> Bool {

  response = nil
  data_received = []

  if !(is_Initialized(sock: sock) && is_binded(sock: sock) && is_listened(sock: sock)){
    return false
  }

  if miliseconds_start_timeout > 0 {
    var mi_wait_poll = Poll_Of_Events ()

    if !set_Receive(mi_poll: &mi_wait_poll, sock: sock){
      return false
    }

    if !(poll_Wait(mi_poll: &mi_wait_poll, miliseconds_timeout: Int32 (miliseconds_start_timeout)) &&
      is_Receive(mi_poll: mi_wait_poll, sock: sock)){

        close(mi_poll: &mi_wait_poll)
        return false
    }

    close(mi_poll: &mi_wait_poll)
  }


  let proto = sock.addr.addr_typ

  var stor_addr = sockaddr()
  var stor_len: socklen_t = socklen_t(MemoryLayout<sockaddr>.stride)


  if proto == .tcp {

    let mi_sock: Dulce_Socket_Descriptor = accept(sock.sock, &stor_addr, &stor_len)

    if mi_sock == C_Socket_Invalid {
      return false
    }

    let mi_family: Address_Family? = from_Number(from: Int32 (stor_addr.sa_family))

    if !(mi_family != nil && (mi_family == .ipv4 || mi_family == .ipv6)){
      return false
    }

    var tmp_socket = Socket_Dulce (sock: mi_sock, addr: Addresses(addr_typ: proto, addr_arr: []),
      binded: false, connected: false, listened: false)

    if mi_family == .ipv4 {
      let mi_addr = c_to_ipv4_address(&stor_addr)

      tmp_socket.addr.addr_arr.append(.ipv4(mi_addr))
    }

    if mi_family == .ipv6 {
      let mi_addr = c_to_ipv6_address(&stor_addr)

      tmp_socket.addr.addr_arr.append(.ipv6(mi_addr))
    }

    response = tmp_socket
    return true
  }

  // udp
  if proto == .udp {
    var mi_arr = [UInt8](repeating: 0, count: 65535)

    let mi_len = recvfrom(sock.sock, &mi_arr, mi_arr.count - 1, 0, &stor_addr, &stor_len)

    if mi_len == C_Socket_Error || mi_len < 1 {
      return false
    }

    let mi_family: Address_Family? = from_Number(from: Int32 (stor_addr.sa_family))

    if !(mi_family != nil && (mi_family == .ipv4 || mi_family == .ipv6)){
      return false
    }

    var mi_addr2 : Addresses = Addresses(addr_typ: .udp, addr_arr: [])

    if mi_family == .ipv4 {
      let mi_addr = c_to_ipv4_address(&stor_addr)

      mi_addr2.addr_arr.append(.ipv4(mi_addr))
    }

    if mi_family == .ipv6 {
      let mi_addr = c_to_ipv6_address(&stor_addr)

      mi_addr2.addr_arr.append(.ipv6(mi_addr))
    }

    response = create_Socket(from_address: mi_addr2)
    data_received = [UInt8](mi_arr[mi_arr.startIndex ..< mi_arr.startIndex + mi_len])

    return response != nil

  }

  return false
}

func string_Error() -> String {
  var message_a = [UInt8](repeating: 0, count: 260)
  var length_a  = Int32 (message_a.count - 1)

  c_show_error(&message_a, &length_a)

  return String(decoding: message_a[message_a.startIndex ..< message_a.startIndex + Int(length_a)] , as: UTF8.self)

}

func dulce_Connect (
  sock: inout Socket_Dulce
) -> Bool {
  if !(is_Initialized(sock: sock) && sock.addr.addr_arr.count > 0){
    return false
  }

  if sock.addr.addr_typ == .udp {
    sock.connected = true
    return true
  }
  var OK = false

  switch sock.addr.addr_arr.first! {

  case .ipv4(var mi_addr):
    var mi_addr2 = c_from_ipv4_address(&mi_addr)

    if connect(sock.sock, &mi_addr2, socklen_t (MemoryLayout<sockaddr_in>.stride)) != C_Socket_Error {
      OK = true
    }

  case .ipv6(var mi_addr):
    var mi_addr2 = c_from_ipv6_address(&mi_addr)

    if connect(sock.sock, &mi_addr2, socklen_t (MemoryLayout<sockaddr_in6>.stride)) != C_Socket_Error {
      OK = true
    }

  default:
    OK = false
  }

  return OK
}

func port_Number (from: Address) -> UInt16 {
  let mi_port = switch from {

  case .ipv4(let mi_p):
    mi_p.sin_port

  case .ipv6(let mi_p):
    mi_p.sin6_port

  default:
    in_port_t(0)
  }

  return ntohs(mi_port)

}

func port_String (from: Address) -> String {
  return String(port_Number(from: from))
}

func address_String (from: Address) -> String {

  var addr = [UInt8](repeating: 0, count: Int (INET6_ADDRSTRLEN))

  switch from {

  case .ipv4(var mi_p):
    inet_ntop (AF_INET, &mi_p.sin_addr, &addr, socklen_t (INET_ADDRSTRLEN))

  case .ipv6(var mi_p):
    inet_ntop (AF_INET6, &mi_p.sin6_addr, &addr, socklen_t (INET6_ADDRSTRLEN))

  default:
    _ = 1

  }
  let fir = addr.firstIndex(of: 0)
  if fir == nil {

    return String(decoding: addr , as: UTF8.self)
  }
  return String(decoding: addr[addr.startIndex ..< fir!] , as: UTF8.self)

}

func close (sock: inout Socket_Dulce) -> Void {
  if !is_Initialized(sock: sock){
    return
  }
  #if os(Windows)

    closesocket(sock.sock)

  #else

    close(sock.sock)

  #endif

  sock.sock = 0
  sock.binded = false
  sock.connected = false
  sock.listened = false
  sock.addr.addr_arr = []
  sock.addr.addr_typ = .none
}

func send (
  sock: Socket_Dulce,
  data_to_send: inout [UInt8],
  send_count: inout Int,
  miliseconds_start_timeout: UInt32 = 0, // default is wait forever
  miliseconds_next_timeouts: UInt32 = 0 // default is wait forever
) -> Bool {

  send_count = 0

  if !(is_Initialized(sock: sock) && data_to_send.count > 0 && (sock.addr.addr_typ == .udp || sock.addr.addr_typ == .tcp)) {
    return false
  }

  var (addr, addr_len) = switch sock.addr.addr_arr.first {

    case .ipv4(var mi_q):
      (c_from_ipv4_address(&mi_q), (MemoryLayout<sockaddr_in>).stride)

    case .ipv6(var mi_q):
      (c_from_ipv6_address(&mi_q), (MemoryLayout<sockaddr_in6>).stride)

    default:
      (sockaddr(), 0)
  }

  if addr_len == 0 {
    return false
  }

  var mi_wait_poll = Poll_Of_Events ()

  if miliseconds_start_timeout > 0 || miliseconds_next_timeouts > 0 {
    if !set_Send(mi_poll: &mi_wait_poll, sock: sock) {
      return false
    }

    if miliseconds_start_timeout > 0 {
      if !(poll_Wait(mi_poll: &mi_wait_poll, miliseconds_timeout: Int32 (miliseconds_start_timeout)) &&
        is_Send(mi_poll: mi_wait_poll, sock: sock)){

          close(mi_poll: &mi_wait_poll)
          return false
      }
    }
  }

  var pos = data_to_send.startIndex
  var remaining = data_to_send.count
  var sended_length = 0
  var total_sended = 0

  while true {
    if sock.addr.addr_typ == .tcp {
      sended_length = send(sock.sock, &data_to_send[pos], remaining, 0)

    }

    if sock.addr.addr_typ == .udp {
      sended_length = sendto(sock.sock, &data_to_send[pos], remaining, 0, &addr, socklen_t(addr_len))
    }

    if sended_length < 1 || sended_length == C_Socket_Error {
      break
    }

    pos += sended_length

    total_sended += sended_length

    if remaining == sended_length {
      break
    }

    remaining -= sended_length

    if remaining < 1 {
      break
    }

    if miliseconds_next_timeouts > 0 {
      reset_Results(mi_poll: &mi_wait_poll)

      if !(poll_Wait(mi_poll: &mi_wait_poll, miliseconds_timeout: Int32(miliseconds_next_timeouts))
        && is_Send(mi_poll: mi_wait_poll, sock: sock)){
          break
      }
    }

  }

  send_count = total_sended

  if miliseconds_start_timeout > 0 || miliseconds_next_timeouts > 0 {
    close(mi_poll: &mi_wait_poll)
  }
  return true
}

func receive (
  sock: Socket_Dulce,
  data_received: inout [UInt8],
  received_count: inout Int,
  udp_received_addresses: inout Addresses?,
  miliseconds_start_timeout: UInt32 = 0, // default is wait forever
  miliseconds_next_timeouts: UInt32 = 0 // default is wait forever
) -> Bool {

  data_received = []
  received_count = 0
  udp_received_addresses = nil

  if !(is_Initialized(sock: sock) && (sock.addr.addr_typ == .udp || sock.addr.addr_typ == .tcp)) {
    return false
  }

  var mi_wait_poll = Poll_Of_Events ()

  if miliseconds_start_timeout > 0 || miliseconds_next_timeouts > 0 {
    if !set_Receive(mi_poll: &mi_wait_poll, sock: sock) {
      return false
    }

    if miliseconds_start_timeout > 0 {
      if !(poll_Wait(mi_poll: &mi_wait_poll, miliseconds_timeout: Int32 (miliseconds_start_timeout)) &&
        is_Receive(mi_poll: mi_wait_poll, sock: sock)){

          close(mi_poll: &mi_wait_poll)
          return false
      }
    }
  }

  var final_data : [UInt8] = []

  var mi_arr = [UInt8](repeating: 0, count: 65535)

  var receive_length = 0
  var total_received = 0

  var mi_udp_addresses = Addresses(addr_typ: .udp, addr_arr: [])
  var mi_udp_sockaddr = sockaddr ()
  var mi_udp_sockaddr_len = socklen_t (MemoryLayout<sockaddr>.stride)

  while true {
    if sock.addr.addr_typ == .tcp {
      receive_length = recv(sock.sock, &mi_arr[mi_arr.startIndex], mi_arr.count, 0)

    }

    if sock.addr.addr_typ == .udp {

      receive_length = recvfrom(sock.sock, &mi_arr[mi_arr.startIndex], mi_arr.count, 0,
       &mi_udp_sockaddr, &mi_udp_sockaddr_len)

      let mi_family: Address_Family? = from_Number(from: Int32 (mi_udp_sockaddr.sa_family))

      if mi_family == .ipv4{
        let mi_q = c_to_ipv4_address(&mi_udp_sockaddr)
        mi_udp_addresses.addr_arr.append(.ipv4(mi_q))

      }
      if mi_family == .ipv6{
        let mi_q = c_to_ipv6_address(&mi_udp_sockaddr)
        mi_udp_addresses.addr_arr.append(.ipv6(mi_q))
      }
      mi_udp_sockaddr_len = socklen_t (MemoryLayout<sockaddr>.stride)
    }

    if receive_length < 1 || receive_length == C_Socket_Error {
      break
    }

    total_received += receive_length

    final_data.append(contentsOf: mi_arr[mi_arr.startIndex ..< mi_arr.startIndex + receive_length])

    if miliseconds_next_timeouts > 0 {
      reset_Results(mi_poll: &mi_wait_poll)

      if !(poll_Wait(mi_poll: &mi_wait_poll, miliseconds_timeout: Int32(miliseconds_next_timeouts))
        && is_Receive(mi_poll: mi_wait_poll, sock: sock)){
          break
      }
    }
  }

  data_received = final_data
  received_count = total_received

  if sock.addr.addr_typ == .udp {
    udp_received_addresses = mi_udp_addresses
  }

  if miliseconds_start_timeout > 0 || miliseconds_next_timeouts > 0 {
    close(mi_poll: &mi_wait_poll)
  }
  return true
}


