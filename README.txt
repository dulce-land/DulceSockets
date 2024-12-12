
DulceSockets
=====================

Version: "Initial" (0.0.1-dev)

DulceSockets is a small, powerfull, portable and easy to use Swift network lib.
It supports ipv4 ipv6 udp tcp raw level 2 and raw level 3,
Fully Asynchronous Use but with Internal Avanced Synchronous I/O Multiplexing
and can 'listen' with ipv6, too.


Before Version 8.0.0 this is a work in progress.

DulceSockets now is in a Fully-Rework.

The Planned Roadmap is:

  1º to work in all OS's supported by Swift, starting  with linux =>
    mswindows => mcosx => "and et.all".
  2º lower the quantitie of subprograms need to "start working", and yet less
    boilerplate inherited from C BSD sockets, with more powerfull simplicity.
  3º raw socket support, L2 and L3, when OS support it.
  5º Fully Asynchronous Use but still with the benefits of advanced synchronous
    operation.
  6º A Local and Distributed Fully Mesh Network Support:
      6.2º) Fully Cryptographic Support against Quantum _and_ Classic Algorithms with:
          6.2.2º) Public Key infrastructure,
          6.2.3º) Key Encapsulate Message,
          6.2.4º) Signature,
          6.2.5º) Symmetric Encryption, with at least 512 bits of security
                against quantum computer algorithms.
      6.3º) Risk Management and virtually invulnerable.
          6.3.2º) Even if an attacker manages to crack a key with an even more
            monstrous quantum super computer, for example, with infinite memory
            and half the infinite number of qubits, this cracker would
            take hundreds of months (tens of years) to crack a single key
            and he needs crack _4_ keys to achieve some impersonation, but even
            then, for only two network nodes; but
            these keys are changed and _invalidated_ between every 5
            to 15 minutes and the entire network does this.
  7º and beyond) TBD.

Maintenance Status: Very Active.

DulceSockets is written in Swift 6.0.1+ and C.

USAGE
-----

  ([Work In Progress])


Main repository
---------------

  https://github.com/dulce-land/DulceSockets.git



CONTRIBUTING
------------

  We will be happy in known where you use DulceSockets. :-)

DOC
---

  ([Work In Progress])


THANKS
------

To Brian "Beejs Jorgensen" Hall, because his book "the Beej's Guide to Network Programming"
and to All people, past present and future, that made Life better to Live. Thanks All!!


LICENSE
-------

The DulceSockets license 2024-Present

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>

SPDX-License-Identifier: Unlicense
