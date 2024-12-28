// The Swift Programming Language
// https://docs.swift.org/swift-book

import CDulceSockets
import Foundation

public struct Address {
  var ai_family : Int32 = 0   // AF_XXX
  var ai_socktype : Int32 = 0 // sock_XXX
  var ai_protocol : Int32 = 0 // 0 (auto) || IPPROTO_TCP || IPPROTO_UDP
  var ai_addrlen  : UInt32 = 0
  var ai_addr : sockaddr?
}

public enum Address_Family {
  case ipv4
  case ipv6
  case ipany
}

public enum Address_Type {
  case none
  case udp
  case tcp
}

public struct Addresses {
  public internal(set) var addr_typ  : Address_Type  = .none
  public internal(set) var addr_arr  : [Address]     = []

  public init() {}

  public init(addr_typ: Address_Type, addr_arr: [Address]) {
    self.addr_typ = addr_typ
    self.addr_arr = addr_arr
  }

  public init(addr_typ: Address_Type) {
    self.addr_typ = addr_typ
    self.addr_arr = []
  }

  public init(addr_arr: [Address]) {
    self.addr_typ = .none
    self.addr_arr = addr_arr
  }

}

public struct Socket_Dulce {
  var sock : Dulce_Socket_Descriptor = 0
  var addr : Addresses  = Addresses()
  var binded    : Bool  = false
  var connected : Bool  = false
  var listened  : Bool  = false
}

public func is_Initialized (sock: Socket_Dulce) -> Bool {
  return sock.sock > 0
}

public func is_Binded (sock: Socket_Dulce) -> Bool {
  return sock.binded
}

public func is_Listened (sock: Socket_Dulce) -> Bool {
  return sock.listened
}


public func to_Number (from: Address_Family) -> Int32 {
  let mi_family  = switch from {
    case .ipany: AF_UNSPEC
    case .ipv6: AF_INET6
    case .ipv4: AF_INET
  }
  return mi_family
}

public func to_Number (from: Address_Type) -> Int32 {
  let mi_address_type  = switch from {
    case .none: Int32(-1)
    case .tcp: c_sock_stream
    case .udp: c_sock_dgram
  }
  return mi_address_type
}


public func from_Number (from: Int32) -> Address_Family? {
  let mi_family : Address_Family? = switch from {
    case AF_UNSPEC: .ipany
    case AF_INET6:  .ipv6
    case AF_INET:   .ipv4
    default: nil
  }
  return mi_family
}

public func from_Number (from: Int32) -> Address_Type? {
  let mi_address_type : Address_Type? = switch from {
    case Int32(-1): Address_Type.none
    case c_sock_stream: .tcp
    case c_sock_dgram:  .udp

    default: nil
  }
  return mi_address_type
}

public func create_Address (host: String, port: String, address_family: Address_Family,
  address_type: Address_Type) -> Addresses?
{
  if address_type == .none {
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

  var mi_address2 = Address()

  repeat {

    mi_address2.ai_family = mi_servinfo!.pointee.ai_family
    mi_address2.ai_socktype = mi_servinfo!.pointee.ai_socktype
    mi_address2.ai_protocol = mi_servinfo!.pointee.ai_protocol
    mi_address2.ai_addrlen  = mi_servinfo!.pointee.ai_addrlen
    mi_address2.ai_addr = mi_servinfo!.pointee.ai_addr.pointee

    mi_address.addr_arr.append (mi_address2)

    mi_servinfo = mi_servinfo!.pointee.ai_next

  } while mi_servinfo != nil

  freeaddrinfo(servinfo)

  return mi_address
}


public func create_Socket (from_address: Addresses, need_bind: Bool = false, need_listen: Bool = false,
  listen_backlog: UInt = 10) -> Socket_Dulce? {

  if from_address.addr_arr.count < 1 || from_address.addr_typ == .none {
    return nil
  }

  var mi_socket = Socket_Dulce()

  mi_socket.addr.addr_typ = from_address.addr_typ
  mi_socket.addr.addr_arr = []

  var OK : Bool = false

  loop1_label:
  for mi_address in from_address.addr_arr {

    mi_socket.sock = socket(mi_address.ai_family, mi_address.ai_socktype, mi_address.ai_protocol)

    if mi_socket.sock == C_Socket_Invalid {
      mi_socket.sock = 0
      OK = false
      continue loop1_label
    }

    mi_socket.addr.addr_arr.append(mi_address)

    OK = true

    if need_bind {
      c_reuse_address(mi_socket.sock)
      let mi_bind = C_Socket_Error

      // let mi_bind = bind (mi_socket.sock, &mi_address.ai_addr, mi_address.ai_addrlen)

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
      return mi_socket
    }
  }

  return nil
}

public func get_Socket (sock: Socket_Dulce) -> Dulce_Socket_Descriptor {
  return sock.sock
}

public func wait_Connection (
  sock: Socket_Dulce,
  response: inout Socket_Dulce?,
  data_received: inout [UInt8],
  miliseconds_start_timeout: UInt32 = 0
) -> Bool {

  response = nil
  data_received = []

  if !(is_Initialized(sock: sock) && is_Binded(sock: sock) && is_Listened(sock: sock)){
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

  var stor_addr = sockaddr()
  var stor_len: socklen_t = socklen_t(MemoryLayout<sockaddr>.stride)

  if sock.addr.addr_typ == .tcp {

    let mi_sock: Dulce_Socket_Descriptor = accept(sock.sock, &stor_addr, &stor_len)

    if mi_sock == C_Socket_Invalid {
      return false
    }

    let mi_family: Address_Family? = from_Number(from: Int32 (stor_addr.sa_family))

    if !(mi_family != nil && (mi_family == .ipv4 || mi_family == .ipv6)){
      return false
    }

    var mi_address = Address()

    mi_address.ai_family = Int32 (stor_addr.sa_family)
    mi_address.ai_socktype = to_Number(from: sock.addr.addr_typ)
    mi_address.ai_protocol = sock.addr.addr_arr[sock.addr.addr_arr.startIndex].ai_protocol
    mi_address.ai_addrlen = stor_len
    // mi_address.ai_addr = stor_addr


    let tmp_socket = Socket_Dulce (sock: mi_sock, addr: Addresses(addr_typ: sock.addr.addr_typ, addr_arr: [mi_address]),
      binded: false, connected: false, listened: false)

    response = tmp_socket
    return true
  }

  if sock.addr.addr_typ == .udp {
    var mi_arr = [UInt8](repeating: 0, count: 65535)

    let mi_len = recvfrom(sock.sock, &mi_arr, mi_arr.count - 1, 0, &stor_addr, &stor_len)

    if mi_len == C_Socket_Error || mi_len < 1 {
      return false
    }

    let mi_family: Address_Family? = from_Number(from: Int32 (stor_addr.sa_family))

    if !(mi_family != nil && (mi_family == .ipv4 || mi_family == .ipv6)){
      return false
    }

    var mi_address = Address()

    mi_address.ai_family = Int32 (stor_addr.sa_family)
    mi_address.ai_socktype = to_Number(from: sock.addr.addr_typ)
    mi_address.ai_protocol = sock.addr.addr_arr[sock.addr.addr_arr.startIndex].ai_protocol
    mi_address.ai_addrlen = stor_len
    // mi_address.ai_addr = stor_addr

    let mi_addr2 : Addresses = Addresses(addr_typ: .udp, addr_arr: [mi_address])

    response = create_Socket(from_address: mi_addr2)
    data_received = [UInt8](mi_arr[mi_arr.startIndex ..< mi_arr.startIndex + mi_len])

    return response != nil
  }

  return false
}

public func string_Error() -> String {
  var message_a = [UInt8](repeating: 0, count: 260)
  var length_a  = Int32 (message_a.count - 1)

  c_show_error(&message_a, &length_a)

  return String(decoding: message_a[message_a.startIndex ..< message_a.startIndex + Int(length_a)] , as: UTF8.self)

}

public func dulce_Connect (
  sock: inout Socket_Dulce
) -> Bool {
  if !(is_Initialized(sock: sock) && sock.addr.addr_arr.count > 0){
    return false
  }

  if sock.addr.addr_typ == .udp {
    sock.connected = true
    return true
  }

  return false //tbr
  // return C_Socket_Error != connect(sock.sock, &sock.addr.addr_arr[sock.addr.addr_arr.startIndex].ai_addr,
  //   sock.addr.addr_arr[sock.addr.addr_arr.startIndex].ai_addrlen)
}

public func port_Number (from: Address) -> UInt16 {

  let addr_family : Address_Family? = from_Number(from: from.ai_family)

  let misoa = from.ai_addr

  var mi_port : UInt16 = 0

  if addr_family == .ipv4 {

    let mi_raw_addr =
      UnsafeMutableRawPointer.allocate(byteCount: Int (from.ai_addrlen),
      alignment: MemoryLayout<sockaddr_in>.alignment)

    defer {
      mi_raw_addr.deallocate()
    }

    mi_raw_addr.storeBytes(of: misoa!, as: sockaddr.self)

    let mi_addr_sockaddr_in = mi_raw_addr.load(as: sockaddr_in.self)
    mi_port = ntohs(mi_addr_sockaddr_in.sin_port)

  }

  if addr_family == .ipv6 {

    let mi_raw_addr =
      UnsafeMutableRawPointer.allocate(byteCount: Int (from.ai_addrlen),
      alignment: MemoryLayout<sockaddr_in6>.alignment)

    defer {
      mi_raw_addr.deallocate()
    }

    mi_raw_addr.storeBytes(of: misoa!, as: sockaddr.self)

    let mi_addr_sockaddr_in = mi_raw_addr.load(as: sockaddr_in6.self)
    mi_port = ntohs(mi_addr_sockaddr_in.sin6_port)

  }

  return mi_port
}

public func port_String (from: Address) -> String {
  return String(port_Number(from: from))
}

public func address_String (from: Address) -> [CChar] {

  var mi_buffer_array  = [CChar](repeating: 0, count: Int (INET6_ADDRSTRLEN + 1))

  let misoa = from.ai_addr;

  let addr_family : Address_Family? = from_Number(from: from.ai_family)

  if addr_family == nil {
    return [0]
  }

  if addr_family == .ipv4 {

    let mi_raw_addr = UnsafeMutableRawPointer.allocate(byteCount: Int (from.ai_addrlen),
      alignment: MemoryLayout<sockaddr_in>.alignment)

    defer {
       mi_raw_addr.deallocate()
    }

    mi_raw_addr.storeBytes(of: misoa!, as: sockaddr.self)

    let mi_sock_in = mi_raw_addr.load(as: sockaddr_in.self)

    var mi_sinaddr = mi_sock_in.sin_addr

    _ = inet_ntop(PF_INET, &mi_sinaddr, // htonl ?
          &mi_buffer_array[mi_buffer_array.startIndex], socklen_t (INET6_ADDRSTRLEN))

  } else if addr_family == .ipv6 {

    let mi_raw_addr = UnsafeMutableRawPointer.allocate(byteCount: Int (from.ai_addrlen),
      alignment: MemoryLayout<sockaddr_in6>.alignment)

    defer {
       mi_raw_addr.deallocate()
    }

    mi_raw_addr.storeBytes(of: misoa!, as: sockaddr.self)

    let mi_sock_in = mi_raw_addr.load(as: sockaddr_in6.self)

    var mi_sinaddr = mi_sock_in.sin6_addr

    _ = inet_ntop(PF_INET6, &mi_sinaddr, // htonl ?
          &mi_buffer_array[mi_buffer_array.startIndex], socklen_t (INET6_ADDRSTRLEN))

  } else {
    return [90,15]
  }

  return mi_buffer_array
}

//   var mi_buffer_array: [UInt8] = [UInt8](repeating: 0, count: Int (INET6_ADDRSTRLEN))

//   var mi_typ = from.ai_addr

//   var mi_raw_addr = UnsafeRawPointer.initializeMemory(as: sockaddr.self, from: &mi_typ, count: 1)

//   // = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<sockaddr>.stride,
//   //   alignment: MemoryLayout<sockaddr>.alignment)

//   mi_raw_addr.storeBytes(of: from.ai_addr, as: sockaddr.self)

//   let addr_family : Address_Family? = from_Number(from: from.ai_family)

//   if addr_family == .ipv4 {
//     let mi_addr_sockaddr_in = mi_raw_addr.load(as: sockaddr_in.self)
//     var mi_sinaddr = mi_addr_sockaddr_in.sin_addr

//     if inet_ntop (AF_INET, &mi_sinaddr, &mi_buffer_array, socklen_t (INET_ADDRSTRLEN)) == nil {
//       return [0]
//     }
//   }

//   if addr_family == .ipv6 {
//     let mi_addr_sockaddr_in6 = mi_raw_addr.load(as: sockaddr_in6.self)
//     var mi_sinaddr6 = mi_addr_sockaddr_in6.sin6_addr

//     if inet_ntop (AF_INET6, &mi_sinaddr6, &mi_buffer_array, socklen_t (INET6_ADDRSTRLEN)) == nil {
//       return [0]
//     }
//   }

//   // mi_raw_addr.deallocate()

//   return mi_buffer_array
// }

public func close (sock: inout Socket_Dulce) -> Void {
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


public func send (
  sock: inout Socket_Dulce,
  data_to_send: inout [UInt8],
  send_count: inout Int,
  miliseconds_start_timeout: UInt32 = 0, // default is wait forever
  miliseconds_next_timeouts: UInt32 = 0 // default is wait forever
) -> Bool {

  send_count = 0

  if !(is_Initialized(sock: sock) && data_to_send.count > 0 && (sock.addr.addr_typ == .udp || sock.addr.addr_typ == .tcp)) {
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

    // if sock.addr.addr_typ == .udp {
    //   sended_length = sendto(sock.sock, &data_to_send[pos], remaining, 0,
    //     &sock.addr.addr_arr[sock.addr.addr_arr.startIndex].ai_addr,
    //     sock.addr.addr_arr[sock.addr.addr_arr.startIndex].ai_addrlen)
    // }

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

public func receive (
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

  var mi_address = sock.addr.addr_arr[sock.addr.addr_arr.startIndex]
  // mi_address.ai_addr = sockaddr()

  var mi_udp_sockaddr = sockaddr ()
  var mi_udp_sockaddr_len = socklen_t (MemoryLayout<sockaddr>.stride)

  while true {
    if sock.addr.addr_typ == .tcp {
      receive_length = recv(sock.sock, &mi_arr[mi_arr.startIndex], mi_arr.count, 0)

    }

    if sock.addr.addr_typ == .udp {

      receive_length = recvfrom(sock.sock, &mi_arr[mi_arr.startIndex], mi_arr.count, 0,
       &mi_udp_sockaddr, &mi_udp_sockaddr_len)

      // mi_address.ai_addr = mi_udp_sockaddr
      mi_address.ai_addrlen = mi_udp_sockaddr_len

      mi_udp_sockaddr = sockaddr()
      mi_udp_sockaddr_len = socklen_t (MemoryLayout<sockaddr>.stride)

      mi_udp_addresses.addr_arr.append(mi_address)

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


