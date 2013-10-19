program P_FacTotum;

uses
    Vcl.Forms,
    SysUtils,
    Classes,
    Windows,
    Vcl.Dialogs,
    Vcl.Themes,
    Vcl.Styles,
    System.UITypes,
    Winapi.ShellAPI,
    U_Main        in 'U_Main.pas' {fFacTotum},
    U_Functions   in 'Units\U_Functions.pas',
    U_DataBase    in 'Units\U_DataBase.pas',
    U_Threads     in 'Units\U_Threads.pas',
    U_InputTasks  in 'Units\U_InputTasks.pas',
    U_Download    in 'Units\U_Download.pas',
    U_Events      in 'Units\U_Events.pas',
    U_OutputTasks in 'Units\U_OutputTasks.pas',
    U_Parser      in 'Units\U_Parser.pas',
    U_Files       in 'Units\U_Files.pas';

{$R *.res}
{$R resources.res}

var
    rStream:  tResourceStream;
    fStream:  tFileStream;
    fName,
    sName:    string;
    sAppPath: string;
begin
    application.initialize;

    sEventHdlr         := eventHandler.create;
    sTaskMgr           := taskManager.create;
    sUpdateParser      := updateParser.create;
    sDownloadMgr       := downloadManager.create;
    sFileMgr           := tFileManager.create;
    sdbMgr             := dbManager.create;

    sAppPath := includeTrailingPathDelimiter(extractFileDir(application.exeName));

    if not directoryExists('resources') then
        if not createDir('resources') then
            exit;

    if not fileExists(sAppPath + 'resources\' + 'sqlite3.dll') then
    begin
        fname   := sAppPath + 'resources\' + 'sqlite3.dll';
        rStream := tResourceStream.create(hInstance, 'dSqlite', RT_RCDATA);
        try
            fStream := tFileStream.create(fname, fmCreate);
            try
                fStream.copyFrom(rStream, 0);
            finally
                fStream.free;
            end;
        finally
            rStream.free;
        end;

        if not fileExists(sAppPath + 'resources\' + 'sqlite3.dll') then
        begin
            messageDlg('Impossibile caricare la libreria ''sqlite3.dll''', mtError, [mbOK], 0);
            exit;
        end;
    end;

    sName := getEnvironmentVariable('WINDIR') + '\fonts\erasmd.ttf';
    if not fileExists( sName ) then
    begin
        fName   := sAppPath + 'resources\' + 'erasmd.ttf';
        rStream := tResourceStream.create(hInstance, 'dErasMD', RT_RCDATA);
        try
            fStream := tFileStream.create(fname, fmCreate);
            try
                fStream.copyFrom(rStream, 0);
            finally
                fStream.free;
            end;
        finally
            rStream.free;
        end;

        addFontResource( pchar(sAppPath + 'resources\' + 'erasmd.ttf') );

        if fileExists(fName) then
        begin
            if tFileManager.executeFileOperation(application.handle, FO_COPY, fName, sName) then
                ShowMessage('ok');
            addFontResource( pchar(sName) );
        end
        else
             messageDlg('Impossibile caricare il font ''erasmd.ttf''', mtWarning, [mbOK], 0);
    end;

    application.mainFormOnTaskbar := true;
    tStyleManager.trySetStyle('Metropolis UI Dark');
    application.createForm(tfFacTotum, fFacTotum);
    application.run;
end.
