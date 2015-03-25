" ===========================
" File: VimPyServer.vim
" Description: A Python server to remote control Vim from telnet or netcat,
"   without X-windows nor vim-server.
" Author: Victor Polo de Gyves Montero <degyves@gmail.com>
" License: BSD
" Website: http://github.com/degyves/VimPyServer
" Version: 0.2.1
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
    try:
      exCommand = clientConnection.recv(4096)
      reply = 'Received ex-command: ' + exCommand
      vim.command('redir @a')
      vim.command( exCommand.strip() )
      vim.command('redir END')
      result = vim.eval('@a')
      if not exCommand:
        break
	#clientConnection.send(reply)
	#clientConnection.send('Result:')
	#clientConnection.send(result)
    except Exception ,e:
      print 'Error on client VIM-PyServer: ' + str(e)
  try:
    clientConnection.close()
  except Exception:
    sys.exc_clear()

def start_server():
  while True:
    try:
      clientConnection, address = telnetServer.accept()
      print 'Connection received from ' + address[0] + ':' + str(address[1])
      # clientConnection.send('VIM telnet server. Received data will be\n')
      # clientConnection.send('interpreted as ex-command. Be cautious.\n')
      start_new_thread( start_client_connection ,( clientConnection, ) )
    except Exception ,e:
      print 'Error on client VIM-PyServer: ' + str(e)
      sys.exc_clear()
try:
  telnetServer.bind((HOST, PORT))
  #Only 1 connection allowed.
  telnetServer.listen(1)
  start_new_thread( start_server  ,() )
  print '*** Vim-PyServer created on ' + HOST + ', port ' + str(PORT) + ' ***' 
  print 'Be cautious, as ANY data received is treated as ex-mode command!' 
  print 'Also, starting and ending carriage return or line feed will be deleted'
  print 'For example, running from another shell:'
  print '    echo "e ~/.bashrc" |nc localhost 9876'
  print 'will be interpreted on the VIM client as:'
  print '    :e ~/.bashrc'
except Exception, e:
  print ('VIM-PyServer exists! (another vim?) on: '+HOST+', port '+str(PORT))
  print 'Error: '+str(e) 
  sys.exc_clear()
endpython
endfunction

function! VimPyServerMessageToClient( message )
python << endpython
import vim
import socket
import sys
HOST='127.0.0.1'
PORT=9875
MESSAGE=''
try:
  env_Host = vim.eval("g:VimPyClient_host")
  print "Using "+ env_Host + " as VimPyClient host."
  HOST=env_Host
except vim.error as msg:
  print "Using default VimPyClient host: "+HOST
try:
  env_Port = vim.eval("g:VimPyClient_port")
  print "Using "+ str(env_Port) +" as VimPyClient port."
  PORT=int(env_Port)
except vim.error as msg:
  print "Using default VimPyClient port: "+str(PORT)
try:
  env_Msg = vim.eval("a:message")
  print "Using "+ env_Msg +" as VimPyClient message."
  MESSAGE=env_Msg
except Exception, e:
  print "Using default VimPyClient message."
def start_client():
  try:
    telnetClient = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    telnetClient.connect((HOST, PORT))
    telnetClient.sendall( MESSAGE )
    telnetClient.close()
  except Exception, e:
    print 'Error on client VimPyServer: ' + str( e )
    telnetClient.close()
start_client()
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

function! g:CheckIfVimperatorVimPyServer()
	if exists("g:vimperatorVimPyServer")
		if g:vimperatorVimPyServer>=1
			call VimPyServerMessageToClient('End Vimperator mode\n')
			let g:vimperatorVimPyServer=0
		endif
	endif 
endfunction

if !exists("autocommands_VimPyServer")
	let autocommands_VimPyServer = 1
	au BufWritePost * call g:CheckIfVimperatorVimPyServer()
endif

