import socket

serverIP = "127.0.0.1"
serverPort = 9008
text_msg_bytes = bytes("żółta gęś", 'utf-8')
num_msg_bytes = (300).to_bytes(4, byteorder='little')

print('PYTHON UDP CLIENT')
client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
client.sendto(num_msg_bytes, (serverIP, serverPort))

buff, address = client.recvfrom(1024)
recv_num = int.from_bytes(buff, byteorder='little')
# print("received response from" + str(address) + ": " + str(buff, 'utf-8'))
print("received response from" + str(address) + ": " + str(int.from_bytes(buff, byteorder='big')))


