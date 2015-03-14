" ===========================
" File: VimPyServer.vim
" Description: A Python server to remote control Vim from telnet or netcat,
"   without X-windows nor vim-server.
" Author: Victor Polo de Gyves Montero <degyves@gmail.com>
" License: BSD
" Website: http://github.com/degyves/VimPyServer
" Version: 0.1
" ===========================

function! CloseVimPyServer()
python << endpython
print 'Closing telnet server...'
telnetServer.shutdown(socket.SHUT_RDWR)
print 'Telnet server -> Bye!'
endpython
endfunction

function! OpenVimPyServer()
python << endpython
import vim
import socket
import sys
from thread import *
HOST='127.0.0.1'
PORT=9876
try:
  env_Port = vim.eval("g:VimPyServer_port")
  print "Using "+ str(env_Port) +" as VimPyServer port."
  PORT=int(env_Port)
except vim.error as msg:
  print "Using default VimPyServer port: "+str(PORT)
try:
  env_Host = vim.eval("g:VimPyServer_host")
  print "Using "+ env_Host + " as VimPyServer host."
  HOST=env_Host
except vim.error as msg:
  print "Using default VimPyServer host: "+HOST

telnetServer = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
def start_client_connection( clientConnection ):
  while True:
    exCommand = clientConnection.recv(4096)
    reply = 'Received ex-command: ' + exCommand
    vim.command('redir @a')
    vim.command( exCommand.strip() )
    vim.command('redir END')
    result = vim.eval('@a')
    if not exCommand:
      break
    clientConnection.send(reply)
    clientConnection.send('Result:')
    clientConnection.send(result)
  clientConnection.close()
def start_server():
  while True:
    try:
      clientConnection, address = telnetServer.accept()
      print 'Connection received from ' + address[0] + ':' + str(address[1])
      clientConnection.send('VIM telnet server. Received data will be\n')
      clientConnection.send('interpreted as ex-command. Be cautious.\n')
      start_new_thread( start_client_connection ,( clientConnection, ) )
    except clientConnection.error as msg:
      print 'Error on client VIM-PyServer: ' + str(msg[0])+', ' + msg[1]
try:
  telnetServer.bind((HOST, PORT))
  #Only 1 connection allowed.
  telnetServer.listen(1)
  print '*** VIM-PyServer ***'
  print 'Be cautious, as ANY data received will be treated as an ex-mode command!' 
  print 'Also, starting and ending carriage return or line feed will be deleted. '
  print ''
  print 'For example, running from another shell:'
  print ''
  print '  echo "e ~/.bashrc" |nc localhost 9876'
  print ''
  print 'will be interpreted on the VIM client as:'
  print ''
  print '  :e ~/.bashrc'
  print ''
  print 'You are encouraged to allow only local connections.'
  start_new_thread( start_server  ,() )
  print 'Vim-PyServer created on ' + HOST + ', port ' + str(PORT) + '.' 
except socket.error as msg:
  print ('VIM-PyServer already exists (maybe another vim) on: ' 
    + HOST +', port ' + str(PORT) )
endpython
endfunction


if !has('python')
	echo "No python detected. VimPyServer will not start."
else
	if !exists("g:VimPyServer_autostart")
		autocmd VimEnter * call OpenVimPyServer()
	else
		if g:VimPyServer_autostart != 0
			autocmd VimEnter * call OpenVimPyServer()
		else
			echo "VimPyServer not started"
		end
	end
end
