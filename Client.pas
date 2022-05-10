uses System;
uses System.Net;
uses System.Net.Sockets;
uses System.Text;

uses MiscData;
uses ConsoleChat;

function ChooseNick: string;
begin
  while true do
  begin
    Result := ReadlnString('Enter nickname:');
    if (Result <> '') and Result.All(ch->ch.IsLetter or ch.IsDigit or (ch='_')) then break;
    writeln('Nickname can only be letters, digits and "_"');
  end;
end;

procedure StartClient;
begin
  try
    var sock := new Socket(
      AddressFamily.InterNetwork,
      SocketType.Stream,
      ProtocolType.Tcp
    );
    
//    var remoteEP := ParseEndPoint(ReadAllText('server adress.txt'));
    var ipAddress := new System.Net.IPAddress(ReadString($'Connect to:').ToWords('.').ConvertAll(byte.Parse));
    var remoteEP := new IPEndPoint(ipAddress, 11000);
    
    sock.Connect(remoteEP);
    
    var nick := ChooseNick;
    sock.Send(Encoding.UTF8.GetBytes(nick));
    System.Console.Clear;
    
    
    var IOLock := new object;
    
    System.Threading.Thread.Create(()->
    while true do
    begin
      
      var msg := ChatOutput.ReadInp;
      if msg = '' then continue;
      lock IOLock do
      begin
        var str := new System.IO.MemoryStream;
        var bw := new System.IO.BinaryWriter(str);
        bw.Write(msg);
        sock.Send(str.ToArray);
      end;
      
      ChatOutput.WriteNewLine($'<{nick}: {msg}', System.ConsoleColor.Green);
      System.Console.ForegroundColor := System.ConsoleColor.Gray;
      
    end).Start;
    
    while true do
    begin
      if sock.Available=0 then
      begin
        Sleep(10);
        continue;
      end;
      
      var ansv := new System.IO.MemoryStream(sock.ReceiveAllBytes);
      lock IOLock do
      begin
        var br := new System.IO.BinaryReader(ansv);
        
        case br.ReadByte of
          
          ServerDisconnected:
          begin
            ChatOutput.WriteNewLine(br.ReadString);
            ChatOutput.WriteNewLine('Press Enter to exit');
            ChatOutput.ReadInp;
            Halt;
          end;
          
          NewMessages:
          begin
            loop br.ReadInt32 do
              ChatOutput.WriteNewLine(br.ReadString);
          end;
          
        end;
        
      end;
      
    end;
    
  except
    on e: Exception do ReadlnString(_ObjectToString(e));
  end;
end;

begin
  StartClient;
end.