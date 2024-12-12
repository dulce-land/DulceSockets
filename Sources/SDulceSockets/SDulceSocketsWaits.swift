
import CDulceSockets

public struct Poll_Of_Events {

  #if os(Windows)

    var handle      : HANDLE = nil
    var event_poll  : [epoll_event] = []
    var socket_poll : [Dulce_Socket_Descriptor] = []

  #else

    var event_poll : [pollfd] = []

  #endif

  var last_wait_returned : Int32 = 0
}

public func is_Initialized (
  mi_poll: Poll_Of_Events
) -> Bool
{
  #if os(Windows)
    if mi_poll.handle == nil {
      return false
    }
  #endif

  if mi_poll.event_poll.count < 1 {
    return false
  }

  return true
}

public func poll_Wait (
  mi_poll: inout Poll_Of_Events,
  miliseconds_timeout: Int32) -> Bool
{
  if !(miliseconds_timeout >= 0 && is_Initialized(mi_poll: mi_poll)) {
    return false
  }

  #if os(Windows)

    mi_poll.last_wait_returned = epoll_wait (mi_poll.handle, &mi_poll.event_poll, mi_poll.event_poll.count, miliseconds_timeout)

  #else

    mi_poll.last_wait_returned = poll(&mi_poll.event_poll, UInt (mi_poll.event_poll.count), miliseconds_timeout)

  #endif

  return mi_poll.last_wait_returned > 0;
}


public func set_Receive (
  mi_poll: inout Poll_Of_Events,
  sock: Socket_Dulce) -> Bool
{
  if !is_Initialized(sock: sock) {
    return false
  }

  #if os(Windows)
    if mi_poll.handle == nil {
      for _ in 1 ... 3 {
        mi_poll.handle = epoll_create1 (0)

        if mi_poll.handle != nil {
          break
        }
      }
      if mi_poll.handle == nil {
        return false
      }
    }
  #endif

  if is_In(mi_poll: mi_poll, sock: sock) {
    return update(mi_poll: &mi_poll, sock: sock, event_bitmap: CShort (POLLIN))
  }

  return add (mi_poll: &mi_poll, sock: sock, event_bitmap: CShort (POLLIN))

}


public func set_Send (
  mi_poll: inout Poll_Of_Events,
  sock: Socket_Dulce) -> Bool
{

  if !is_Initialized(sock: sock){
    return false
  }

  #if os(Windows)
    if mi_poll.handle == nil {
      for _ in 1 ... 3 {
        mi_poll.handle = epoll_create1 (0)

        if mi_poll.handle != nil {
          break
        }
      }
      if mi_poll.handle == nil {
        return false
      }
    }
  #endif

  if is_In(mi_poll: mi_poll, sock: sock) {
    return update(mi_poll: &mi_poll, sock: sock, event_bitmap: CShort (POLLOUT))
  }

  return add (mi_poll: &mi_poll, sock: sock, event_bitmap: CShort (POLLOUT))
}


public func remove (
  mi_poll: inout Poll_Of_Events,
  sock: Socket_Dulce) -> Bool
{

  if !(is_Initialized(sock: sock) && is_Initialized(mi_poll: mi_poll)) {
    return false
  }

  if !is_In(mi_poll: mi_poll, sock: sock) {
    return false
  }

  let tmp_sock = get_Socket(sock: sock)


  #if os(Windows)
    if (0 != epoll (mi_poll.handle, EPOLL_CTL_DEL, tmp_sock, nil)) {
      return false
    }

    let tmp_indx = mi_poll.socket_poll.firstIndex {misock in
      misock == tmp_sock
    }

    if tmp_indx == nil {
      return false
    }

    mi_poll.socket_poll.remove (at: tmp_indx!)
    mi_poll.event_poll.removeLast()

  #else

    let tmp_indx = mi_poll.event_poll.firstIndex { mifd in
      mifd.fd == tmp_sock
    }

    if tmp_indx == nil {
      return false
    }

    mi_poll.event_poll.remove (at: tmp_indx!)

  #endif

  return true
}


public func is_Receive (
  mi_poll: Poll_Of_Events,
  sock: Socket_Dulce) -> Bool {

    if !(is_Initialized(sock: sock) && is_Initialized(mi_poll: mi_poll) && mi_poll.last_wait_returned > 0) {
      return false
    }

    let tmp_sock = get_Socket(sock: sock)

    #if os(Windows)

      let tmp_first = mi_poll.event_poll.startIndex
      let tmp_last  = mi_poll.last_wait_returned

      return nil != mi_poll.event_poll[tmp_first ..< tmp_first + tmp_last].firstIndex { mifd in
        (mifd.data.sock == tmp_sock && mifd.events != 0 && ((mifd.events & Int16 (POLLIN)) != 0))
      }

    #else

      return nil  != mi_poll.event_poll.firstIndex { mifd in
          (mifd.fd == tmp_sock && mifd.revents != 0 && (mifd.revents & Int16 (POLLIN)) != 0)
      }

    #endif
  }


public func is_Send (
  mi_poll: Poll_Of_Events,
  sock: Socket_Dulce) -> Bool {

    if !(is_Initialized(sock: sock) && is_Initialized(mi_poll: mi_poll) && mi_poll.last_wait_returned > 0) {
      return false
    }

    let tmp_sock = get_Socket(sock: sock)


    #if os(Windows)
      let tmp_first = mi_poll.event_poll.startIndex
      let tmp_last  = mi_poll.last_wait_returned

      return nil != mi_poll.event_poll[tmp_first ..< tmp_first + tmp_last].firstIndex { mifd in
        (mifd.data.sock == tmp_sock && mifd.events != 0 && ((mifd.events & Int16 (POLLOUT)) != 0))
      }

    #else

      return nil  != mi_poll.event_poll.firstIndex { mifd in
          (mifd.fd == tmp_sock && mifd.revents != 0 && (mifd.revents & Int16 (POLLOUT)) != 0)
      }

    #endif
}


public func reset_Results (mi_poll: inout Poll_Of_Events) -> Void {

  mi_poll.last_wait_returned = 0;

  #if os(Windows)

    for var elem in mi_poll.event_poll {
      elem.events = 0
      elem.data.hnd = nil
      elem.data.sock = C_Socket_Invalid
    }

  #else

    for var elem in mi_poll.event_poll {
      elem.revents = 0
    }

  #endif
}


public func close (mi_poll: inout Poll_Of_Events) -> Void {

  if !is_Initialized(mi_poll: mi_poll) {
    return
  }

  mi_poll.last_wait_returned =  0
  mi_poll.event_poll   =  []

  #if os(Windows)

    let tmp_spa = mi_poll.socket_poll
    let handle  = mi_poll.handle

    mi_poll.socket_poll  =  []
    mi_poll.handle       =  nil

    if tmp_spa.count > 0 {

      for elem in tmp_spa {

        if elem != C_Socket_Invalid {
          _ = epoll_ctl (handle, EPOLL_CTL_DEL, elem, nil)
        }

      }

    }

    _ = epoll_close (handle)

    handle = nil;
    tmp_spa = []

  #endif
}


func is_In (
  mi_poll: Poll_Of_Events,
  sock: Socket_Dulce
) -> Bool {

  if !(is_Initialized(sock: sock) && is_Initialized(mi_poll: mi_poll)){
    return false
  }

  let tmp_sock = get_Socket(sock: sock)

  #if os(Windows)

    return mi_poll.socket_poll.contains (tmp_sock)

  #else

    return nil != mi_poll.event_poll.firstIndex { mifd in
      mifd.fd == tmp_sock
    }
  #endif
}


// private

//  ToDo: 'internal access' ?
func update (
  mi_poll: inout Poll_Of_Events,
  sock: Socket_Dulce,
  event_bitmap: CShort
) -> Bool {

  if !(is_Initialized(sock: sock) && is_Initialized(mi_poll: mi_poll)){ // && is_in (mi_poll, sock)) {
    return false
  }

  let tmp_sock = sock.sock

  #if os(Windows)

    var mi_event = epoll_event()

    mi_event.events = event_bitmap
    mi_event.data.sock = tmp_sock

    return 0 == epoll_ctl (mi_poll.handle, EPOLL_CTL_MOD, tmp_sock, &mi_event)

  #else

    let tmp_indx = mi_poll.event_poll.firstIndex { mifd in
      (mifd.fd == tmp_sock)
    }

    if tmp_indx == nil {
      return false
    }

    mi_poll.event_poll[tmp_indx!].events = event_bitmap
    mi_poll.event_poll[tmp_indx!].revents = 0

    return true

  #endif
}

//  ToDo: 'internal access' ?
func add (
  mi_poll: inout Poll_Of_Events,
  sock: Socket_Dulce,
  event_bitmap: CShort
) -> Bool {

  if !(is_Initialized(sock: sock) && is_Initialized(mi_poll: mi_poll)) { // && !is_in (mi_poll, sock)) {
    return false
  }

  let tmp_sock = sock.sock

  #if os(Windows)

    var mi_event = epoll_event()

    mi_event.events = event_bitmap
    mi_event.data.sock = tmp_sock

    if (0 != epoll_ctl (mi_poll.handle, EPOLL_CTL_ADD, tmp_sock, &mi_event)) {
      return false
    }

    var mi_event2 = epoll_event()

    mi_event2.events = 0
    mi_event2.data.sock = C_Socket_Invalid

    mi_poll.event_poll.append(mi_event2)
    mi_poll.socket_poll.append(tmp_sock)

  #else

    let mifd = pollfd (fd: tmp_sock, events: event_bitmap, revents: 0)

    mi_poll.event_poll.append(mifd)

  #endif

  return true
}
