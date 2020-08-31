program pcleaner;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  System.StrUtils,
  System.Types,
  Winapi.Windows,
  Winapi.Tlhelp32,
  Vcl.Forms,
  System.Generics.Collections,
  GpLists;

function GetConsoleWindow: HWND; stdcall; external kernel32;



// M�todo milagroso que faz a libera��o da mem�ria
procedure FreeProcessMemory(PID: Integer);
var
  MainHandle: THandle;
begin
  try
    MainHandle := OpenProcess(PROCESS_ALL_ACCESS, False, PID);
    SetProcessWorkingSetSize(MainHandle, $FFFFFFFF, $FFFFFFFF);
    CloseHandle(MainHandle);
  except
  end;

  Application.ProcessMessages;
end;



// M�todo que retorna o PID com base no nome do processo
function GetPID(appname: String): TGpIntegerList;
var
  snapshot: THandle;
  processEntry: TProcessEntry32;
begin
  Result            := TGpIntegerList.Create;
  Result.Duplicates := dupIgnore;
  Result.Sorted     := true;
  appname           := LowerCase(appname);
  snapshot          := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

  if snapshot <> 0 Then
    try
      processEntry.dwSize := Sizeof(processEntry);
      if (Process32First(snapshot, processEntry)) then
        repeat
          if (appname = '--all') or (Pos(appname, LowerCase(ExtractFilename(StrPas(processEntry.szExeFile)))) > 0) then
            Result.Add(processEntry.th32ProcessID);

        until (not Process32Next(snapshot, processEntry));
    finally
      CloseHandle(snapshot);
    end;
end;

var
  PID: Integer;
  PIDList: TGpIntegerList;
  i: Integer;
  Arg: TDictionary<String, String>;



begin
  try
    Arg := TDictionary<String, String>.Create;

    try

      // La�o que percorre os parametros e monta um dict com os argumentos
      for i := 1 to ParamCount do
      begin

        if MatchStr(LowerCase(ParamStr(i)), ['--help', 'help', '?', '-?']) then
          Arg.AddOrSetValue('--help', ParamStr(i))

        else if MatchStr(LowerCase(ParamStr(i)), ['--hide', '-h']) then
          Arg.AddOrSetValue('--hide', ParamStr(i))

          // Caso contenha um parametro do tipo inteiro, entende-se o usuario deseja liberar a mem�ria de um processo especifico (este modelo � o recomendado)
        else if TryStrToInt(ParamStr(i), PID) then
          Arg.AddOrSetValue('PID', ParamStr(i))

          // Caso contenha o parametro --all, entende-se que o usuario deseja liberar a mem�ria de todos os processos
        else if (MatchStr(ParamStr(i), ['-a', '--all'])) then
          Arg.AddOrSetValue('--all', ParamStr(i))

          // Caso contenha o parametro --name, adiciona o valor no proximo argumento ao dicionario (por isso o i + 1)
        else if (MatchStr(ParamStr(i), ['-n', '--name'])) then
          Arg.AddOrSetValue('--name', ParamStr(i + 1))

      end;

      // Se n�o for informado parametro, entende-se que o usuario abriu o exe clicando 2x. Nesse caso � interessande exibir o help
      // Se encontrar o parametro help, lista os comandos, e encerra a aplica��o
      if (ParamCount = 0) or (Arg.ContainsKey('--help')) then
      begin
        Writeln('');
        Writeln('Para identificar a aplica��o por PID:');
        Writeln('   pcleaner.exe <PID>');
        Writeln('');
        Writeln('Para identificar a aplica��o por Nome:');
        Writeln('   pcleaner.exe --name <Nome da Aplica��o>');
        Writeln('');
        Writeln('Para aplicar em todos os processos:');
        Writeln('   pcleaner.exe --all');
        Writeln('');
        Writeln('Para esconder a janela:');
        Writeln('   pcleaner.exe <Comando> --hide');
        Writeln('');
        Writeln('');
        Writeln('Varia��es de comando:');
        Writeln('   --all   | -a ');
        Writeln('   --name  | -n ');
        Writeln('   --hide  | -h ');
        Writeln('   --help  | help | ? | -? ');

        readln;

        exit
      end;

      // Valida��o
      // Os parametros --name --all e PID n�o podem ser utilizados juntos
      if (Arg.ContainsKey('--name')) and (Arg.ContainsKey('--all')) then
      begin
        Writeln('   Os par�metros <--name> e <--all> n�o podem ser utilizados juntos');
        exit
      end;

      if (Arg.ContainsKey('--name')) and (Arg.ContainsKey('PID')) then
      begin
        Writeln('   Os par�metros <--name> e <PID> n�o podem ser utilizados juntos');
        exit
      end;

      if (Arg.ContainsKey('--all')) and (Arg.ContainsKey('PID')) then
      begin
        Writeln('   Os par�metros <--all> e <PID> n�o podem ser utilizados juntos');
        exit
      end;
      // ---

      // Se encontrar o parametro hide, esconde a tela
      if (Arg.ContainsKey('--hide')) then
        ShowWindow(GetConsoleWindow, SW_HIDE);
      // ---

      // Se encontrar o parametro name, libera memoria do processo especificado
      if (Arg.ContainsKey('--name')) then
      begin
        PIDList := GetPID(Arg['--name']);

        for PID in PIDList do
          FreeProcessMemory(PID);

        FreeAndNil(PIDList);
      end

      // Se encontrar o parametro all, libera a memoria de todos os processos
      else if (Arg.ContainsKey('--all')) then
      begin
        PIDList := GetPID('--all');

        for PID in PIDList do
          FreeProcessMemory(PID);

        FreeAndNil(PIDList);
      end

      // Libera a mem�ria do processo com um determinado ID
      else if (Arg.ContainsKey('PID')) then
      begin
        FreeProcessMemory(StrToInt(Arg['PID']));
      end
      else
        Writeln('Informe um PID v�lido');

    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;

  finally
    FreeAndNil(Arg);
  end;

end.
