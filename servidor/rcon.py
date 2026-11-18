#!/usr/bin/env python3
"""Manda un comando a la consola del servidor T'O EPK por RCON (solo desde la propia maquina).
   toepk "whitelist add Nombre"     toepk list     toepk stop"""
import re, socket, struct, sys

def main():
    props = open('/opt/toepk/server.properties', encoding='utf-8').read()
    pw = re.search(r'^rcon\.password=(.*)$', props, re.M).group(1).strip()
    port = int(re.search(r'^rcon\.port=(\d+)', props, re.M).group(1))
    cmd = ' '.join(sys.argv[1:]) or 'list'
    s = socket.create_connection(('127.0.0.1', port), timeout=10)
    def send(i, t, body):
        b = body.encode('utf-8') + b'\x00\x00'
        s.sendall(struct.pack('<iii', len(b) + 8, i, t) + b)
    def recv():
        n = struct.unpack('<i', s.recv(4))[0]
        data = b''
        while len(data) < n: data += s.recv(n - len(data))
        i, t = struct.unpack('<ii', data[:8])
        return i, data[8:-2].decode('utf-8', 'replace')
    send(1, 3, pw)
    if recv()[0] == -1: sys.exit('RCON: contraseña incorrecta')
    send(2, 2, cmd)
    print(re.sub(r'§.', '', recv()[1]))

if __name__ == '__main__':
    try: main()
    except (ConnectionRefusedError, socket.timeout, OSError) as e: sys.exit('el servidor no responde (%s)' % e)
