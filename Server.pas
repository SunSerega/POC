uses System;
uses System.Net;
uses System.Net.Sockets;
uses System.Text;

uses MiscData;

type
  Guy = class
    
    nick: string;
    thr: System.Threading.Thread;
    new_messages := new Queue<string>;
    
  end;

procedure StartListening :=
try

var localEndPoint := ParseEndPoint(ReadAllText('server adress.txt'));

var listener := new Socket(
  AddressFamily.InterNetwork,
  SocketType.Stream,
  ProtocolType.Tcp
);

  listener.Bind(localEndPoint);
  listener.Listen(10);
  
  var Pepo := new List<Guy>;
  
  var addMessage: (string, Guy)->() := (s, snd)->
  foreach var g in Pepo do
    if g <> snd then
      lock g.new_messages do
        g.new_messages.Enqueue(s);
  
  while true do
  begin
    var handler := listener.Accept;
    writeln('New connection');
    
    System.Threading.Thread.Create(()->
    begin
      var g: Guy;
      
      try
        var sock := handler;
        
        var str := new System.IO.MemoryStream;
        var bw := new System.IO.BinaryWriter(str);
        
        lock Pepo do
        begin
          g := new Guy;
          g.nick := Encoding.UTF8.GetString(sock.ReceiveAllBytes);
          if (g.nick = '') or not g.nick.All(ch->ch.IsLetter or ch.IsDigit or (ch='_')) then
          begin
            bw.Write(ServerDisconnected);
            bw.Write('>Server: Error! Wrong name');
            sock.Send(str.ToArray);
            sock.Shutdown(SocketShutdown.Both);
            sock.Close;
            exit;
          end;
          if Pepo.Any(g2->g.nick=g2.nick) then
          begin
            bw.Write(ServerDisconnected);
            bw.Write('>Server: Error! Name already used');
            sock.Send(str.ToArray);
            sock.Shutdown(SocketShutdown.Both);
            sock.Close;
            exit;
          end;
          g.thr := System.Threading.Thread.CurrentThread;
          pepo += g;
        end;
        
        writeln($'New guy is "{g.nick}"');
        addMessage($'{g.nick} just connected', nil);
        
        while true do
        begin
          
          if sock.Available<>0 then
          begin
            var ansv := new System.IO.MemoryStream(sock.ReceiveAllBytes);
            var br := new System.IO.BinaryReader(ansv);
            while ansv.Position < ansv.Length do
            begin
              var text := br.ReadString;
              if text='' then continue;
              var res := $'>{g.nick}: {text}';
              
              addMessage(res, g);
              writeln($'Handled message "{res}"');
            end;
          end;
          
          if g.new_messages.Count <> 0 then
            lock g.new_messages do
            begin
              bw.Write(NewMessages);
              bw.Write(g.new_messages.Count);
              loop g.new_messages.Count do
                bw.Write(g.new_messages.Dequeue);
              sock.Send(str.ToArray);
              str.Position := 0;
              str.SetLength(0);
            end;
          
          Sleep(10);
        end;
        
      except
        on e: Exception do
        begin
          lock 'ErrorLog.txt' do
            System.IO.File.AppendAllText('ErrorLog.txt', _ObjectToString(e) + #10*2);
          writeln($'Guy "{g?.nick}" disconnected because {e.ToString}');
          
          if Pepo.Contains(g) then
          begin
            Pepo.Remove(g);
            addMessage($'Server: {g.nick} disconnected, because of server error', nil);
          end;
          
        end;
      end;
    end).Start;
    
  end;

except
  on e: Exception do ReadlnString(_ObjectToString(e));
end;

begin
  StartListening;
end.