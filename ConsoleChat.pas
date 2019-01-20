unit ConsoleChat;

type
  ///Класс с функционалом для ввода/вывода в виде чата
  ChatOutput = static class
  
    //нужно, чтоб удостоверится, что эта процедура не выполняется в >1 потоке одновременно
    //если вызвали в нескольких - они будут выполнятся по очереди
    private static otp_lock := new object;
    
    //нужно, потому что вызов ввода в нескольких потоках всё сломает
    private static inp_lock := new object;
    
    private static _lines_count: integer := 10;
    
    
    
    static constructor;
    begin
      System.Console.CursorVisible := false;
    end;
    
    ///кол-во строк одновременно помещающихся на экране
    public static property LinesCount: integer read _lines_count write
    begin
      //_lines_count := value;//ToDo
      raise new System.NotImplementedException;
      //надо двигать весь буфер того текста что уже есть, и текста который сейчас вводят... Или ждать пока довведут текст если есть ожидание.
    end;
    
    ///Выводит на экран текст, в форме чата
    public static procedure WriteNewLine(s: string; c: System.ConsoleColor := System.Console.ForegroundColor) :=
    if s.Contains(#10) then
      foreach var l in s.Split(#10) do
        WriteNewLine(l) else
      lock otp_lock do
      begin
        System.Console.ForegroundColor := c;
        
        System.Console.MoveBufferArea(
          0,1,
          System.Console.BufferWidth, LinesCount-1,
          0,0
        );
        
        System.Console.SetCursorPosition(0, LinesCount-1);
        System.Console.Write(s);
        
      end;
    
    ///Вводит текст, в форме чата
    public static function ReadInp: string;
    begin
      var res := new StringBuilder;
      
      lock inp_lock do
      begin
        
        while true do
        begin
          var key := System.Console.ReadKey(true);
          if key.Key=System.ConsoleKey.Enter then break;
          
          if key.Key=System.ConsoleKey.Backspace then
          begin
            
            res.Length -= 1;
            
            lock otp_lock do
            begin
              System.Console.SetCursorPosition(res.Length, LinesCount);
              System.Console.Write(' ');
            end;
            
          end else
          begin
            
            res += key.KeyChar;
            
            lock otp_lock do
            begin
              System.Console.SetCursorPosition(res.Length-1, LinesCount);
              System.Console.Write(key.KeyChar);
            end;
            
          end;
          
        end;
        
        lock otp_lock do
        begin
          System.Console.SetCursorPosition(0, LinesCount);
          System.Console.Write(new string(' ', System.Console.BufferWidth));
        end;
        
      end;
      
      Result := res.ToString;
    end;
    
  end;

end.