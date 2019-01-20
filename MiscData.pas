unit MiscData;

const
  ServerDisconnected: byte = 1;
  NewMessages: byte = 2;

function ParseEndPoint(s: string): System.Net.IPEndPoint;
begin
  var ss := s.Split(new char[](':'), 2);
  var Address := new System.Net.IPAddress(ss[0].Split(new char[]('.'),4).ConvertAll(s->byte.Parse(s)));
  Result := new System.Net.IPEndPoint(Address, ss[1].ToInteger);
end;

function ReceiveAllBytes(f: function(res: array of byte): integer): array of byte;
const MaxBatch = 1024;
begin
  var res := new List<(array of byte, integer)>;
  
  while true do
  begin
    var data := new byte[MaxBatch];
    var rc := f(data);
    res += (data, rc);
    if rc < MaxBatch then break;
  end;
  
  Result := new byte[res.Sum(t->t[1])];
  
  var i := 0;
  foreach var t in res do
  begin
    System.Buffer.BlockCopy(t[0],0, Result,i, t[1]);
    i += t[1];
  end;
  
end;

function ReceiveAllBytes(self: System.Net.Sockets.Socket): array of byte; extensionmethod :=
ReceiveAllBytes(self.Receive);

end.