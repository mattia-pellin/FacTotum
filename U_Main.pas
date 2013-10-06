unit U_Main;

interface

uses
    vcl.controls, vcl.forms, vcl.comCtrls, vcl.stdCtrls, vcl.checkLst, vcl.imgList,
    vcl.extCtrls, vcl.menus, system.sysutils, system.classes, system.uiTypes, dialogs,
    system.types,

    U_DataBase, U_Functions, U_Classes;

type
    tfFacTotum = class(tForm)
        pcTabs: TPageControl;
        tInstaller: TTabSheet;
        tConfiguration: TTabSheet;
        tUpdate: TTabSheet;
        pbCmdInst: TProgressBar;
        lInstall: TLabel;
        clbInstall: TCheckListBox;
        ilFacTotum: TImageList;
        tvConfig: TTreeView;
        rgArchInfo: TRadioGroup;
        leCmdInfo: TLabeledEdit;
        pmSoftware: TPopupMenu;
        pmInsert: TMenuItem;
        pmDelete: TMenuItem;
        lUpdate: TLabel;
        pbUpdate: TProgressBar;
        leVerInfo: TLabeledEdit;
        leUrlInfo: TLabeledEdit;
        pmSetMainCmd: TMenuItem;
        lUpdateProg: TLabel;
        tLog: TTabSheet;
        lCmdInstProg: TLabel;
        bInstall: TButton;
        bUpdate: TButton;
        lvEvents: TListView;
        bEmpty: TButton;
        ilTasks: TImageList;
        bBrowse: TButton;
        lvUpdate: TListView;
        pbSwInst: TProgressBar;
        lSwInstProg: TLabel;

        procedure formCreate(sender: tObject);
        procedure applicationIdleEvents(sender: tObject; var done: boolean);
        procedure bEmptyClick(sender: tObject);
        procedure configureUpdateOnTreeSelect(sender: tObject; node: tTreeNode);
        procedure formClose(sender: tObject; var action: tCloseAction);
        procedure pmInsertClick(sender: tObject);
        procedure tvConfigMouseDown(sender: tObject; button: tMouseButton; shift: tShiftState; x, y: integer);
        procedure pmSoftwarePopup(sender: tObject);
        procedure pmDeleteClick(sender: tObject);
        procedure leCmdInfoExit(sender: tObject);
        procedure leVerInfoExit(sender: tObject);
        procedure leVerInfoKeyPress(sender: tObject; var key: char);
        procedure leUrlInfoExit(sender: tObject);
        procedure leCmdInfoKeyPress(sender: tObject; var key: char);
        procedure leUrlInfoKeyPress(sender: tObject; var key: char);
        procedure rgArchInfoExit(sender: tObject);
        procedure bBrowseClick(sender: tObject);
        procedure leVerInfoKeyDown(sender: tObject; var key: word; shift: tShiftState);
        procedure leVerInfoContextPopup(sender: tObject; mousePos: tPoint; var handled: boolean);
        procedure tvConfigEdited(sender: tObject; node: tTreeNode; var s: string);
        procedure bUpdateClick(sender: tObject);

        procedure fillConfigureSoftwareList;
        procedure sendUpdateSoftwareList;
        procedure fillUpdateSoftwareList;
    end;

const
    FH_URL = 'http://www.filehippo.com/';

var
    fFacTotum: tfFacTotum;

implementation

{$R *.dfm}

    procedure tfFacTotum.configureUpdateOnTreeSelect(sender: tObject; node: tTreeNode);
    var
        isChild: boolean;
        cmdRec:  cmdRecord;
    begin
        isChild            := assigned(node.parent);
        bBrowse.enabled    := isChild;
        leCmdInfo.enabled  := isChild;
        leVerInfo.enabled  := isChild;
        leUrlInfo.enabled  := isChild;
        rgArchInfo.enabled := isChild;

        if isChild then
        begin
            cmdRec               := node.data;
            leCmdInfo.text       := cmdRec.cmmd;
            leVerInfo.text       := cmdRec.vers;
            leUrlInfo.text       := cmdRec.uURL;
            rgArchInfo.itemIndex := cmdRec.arch;

            leCmdInfo.color := tvConfig.color;
            leVerInfo.color := tvConfig.color;
            leUrlInfo.color := tvConfig.color;
        end
        else
        begin
            leUrlInfo.text       := '';
            leCmdInfo.text       := '';
            leVerInfo.text       := '';
            rgArchInfo.itemIndex := -1;
        end;
    end;

    procedure tfFacTotum.formClose(sender: tObject; var action: tCloseAction);
    begin
        sTaskMgr.free;
    end;

    procedure tfFacTotum.fillConfigureSoftwareList;
    var
        software: tList;
        j,
        i:        integer;
        node:     tTreeNode;
        swRec:    swRecord;
    begin
        tvConfig.items.clear;

        software := sDBMgr.getSoftwareList;

        for i := 0 to pred(software.count) do
        begin
            swRec := swRecord(software.items[i]);

            if swRec.hasValidCommands then
                clbInstall.items.add(swRec.name);

            node      := tvConfig.items.add(nil, swRec.name);
            node.data := swRec;

            if not assigned(swRec.commands) then
                continue;

            for j := 0 to pred(swRec.commands.count) do
                tvConfig.items.addChild( node, cmdRecord(swRec.commands[j]).name ).data := cmdRecord(swRec.commands[j]);

            node.expand(true);
        end;
    end;

    procedure tfFacTotum.rgArchInfoExit(Sender: TObject);
    var
        taskUpdate: tTaskRecordUpdate;
        swIndex:    integer;
    begin
        swIndex            := swRecord( sDBMgr.getSoftwareList.items[tvConfig.selected.parent.index] ).guid;

        taskUpdate         := tTaskRecordUpdate.create;
        taskUpdate.field   := dbFieldCmdArch;
        taskUpdate.value   := rgArchInfo.itemIndex.toString;
        taskUpdate.tRecord := recordCommand;
        taskUpdate.pRecord := sDBMgr.getCommandList(swIndex).items[tvConfig.selected.index];

        sTaskMgr.pushTaskToInput(taskUpdate);
    end;

    procedure tfFacTotum.tvConfigEdited(sender: tObject; node: tTreeNode; var s: string);
    var
        taskUpdate: tTaskRecordUpdate;
    begin
        taskUpdate := tTaskRecordUpdate.create;

        if node.hasChildren then
        // E' un software
        begin
            taskUpdate.field   := dbFieldSwName;
            taskUpdate.tRecord := recordSoftware;
        end
        else
        // E' un comando
        begin
            taskUpdate.field   := dbFieldCmdName;
            taskUpdate.tRecord := recordCommand;
        end;
        taskUpdate.pRecord := tvConfig.selected.data;
        taskUpdate.value   := trim(s);
        sTaskMgr.pushTaskToInput(taskUpdate);
    end;

    procedure tfFacTotum.tvConfigMouseDown(sender: tObject; button: tMouseButton; shift: tShiftState; X, Y: integer);
    var
        node: tTreeNode;
    begin
        node := tvConfig.getNodeAt(X, Y);

        if assigned(node) then
            node.selected := true;
    end;

    procedure tfFacTotum.applicationIdleEvents(sender: tObject; var done: boolean);
    var
        taskOut: tTaskOutput;
        event:   tEvent;
    begin
        // TODO: Riscrivere anche la gestione degli eventi come task
        if (sEventHdlr.getErrorCache) then
            tLog.imageIndex := tImageIndex(tiEvtErr);

        if not(sEventHdlr.isEventListEmpty) then
            while not(sEventHdlr.isEventListEmpty) do
                with lvEvents.items.add do
                begin
                    event := sEventHdlr.pullEventFromList;

                    stateIndex := event.eventType;
                    subItems.add(event.eventTime);
                    subItems.add(event.eventDesc);

                    event.free;
                end;

        taskOut := sTaskMgr.pullTaskFromOutput;

        if not assigned(taskOut) then
            exit;

        while( assigned(taskOut) ) do
        begin
            taskOut.exec();
            taskOut.free;
            taskOut := sTaskMgr.pullTaskFromOutput;
        end;
    end;

    procedure tfFacTotum.formCreate(sender: tObject);
    begin
        sEventHdlr          := eventHandler.create;
        sTaskMgr            := taskManager.create;
        sUpdateParser       := updateParser.create;
        sDownloadMgr        := downloadManager.create;
        sFileMgr            := fileManager.create;
        sDBMgr              := dbManager.create;

        fFacTotum.left      := (Screen.Width - Width)   div 2;
        fFacTotum.top       := (Screen.Height - Height) div 2;

        fFacTotum.caption   := fFacTotum.caption + ' v' + getFmtFileVersion(application.exeName);

        sLvUpdate           := lvUpdate;

        application.onIdle  := applicationIdleEvents;

        self.fillConfigureSoftwareList;
        self.fillUpdateSoftwareList;
        self.sendUpdateSoftwareList;
    end;

    procedure tfFacTotum.leCmdInfoExit(sender: tObject);
    var
        taskUpdate: tTaskRecordUpdate;
        swIndex:    integer;
    begin
        leCmdInfo.text := trim(leCmdInfo.text);
        if length(leCmdInfo.text) > 0 then
        begin
            swIndex            := swRecord(tvConfig.selected.parent.data).guid;

            taskUpdate         := tTaskRecordUpdate.create;
            taskUpdate.field   := dbFieldCmdCmmd;
            taskUpdate.value   := leCmdInfo.text;
            taskUpdate.tRecord := recordCommand;
            taskUpdate.pRecord := sDBMgr.getCommandList(swIndex).items[tvConfig.selected.index];

            sTaskMgr.pushTaskToInput(taskUpdate);

            leCmdInfo.color := $0080FF80; // Verde
        end
        else
            leCmdInfo.color := $008080FF; // Rosso
    end;

    procedure tfFacTotum.leCmdInfoKeyPress(Sender: TObject; var Key: Char);
    begin
        if key = #13 then
        begin
            selectNext(sender as tWinControl, true, true);
            key := #0
        end;
    end;

    procedure tfFacTotum.leUrlInfoExit(Sender: TObject);
    var
        taskUpdate: tTaskRecordUpdate;
    begin
        leUrlInfo.text := trim(leUrlInfo.text);
        if length(leUrlInfo.text) > 0 then
        begin
            taskUpdate         := tTaskRecordUpdate.create;
            taskUpdate.field   := dbFieldCmduURL;
            taskUpdate.value   := leUrlInfo.text;
            taskUpdate.tRecord := recordCommand;
            taskUpdate.pRecord := tvConfig.selected.data;

            sTaskMgr.pushTaskToInput(taskUpdate);

            leUrlInfo.color := $0080FF80; // Verde
        end
        else
            leUrlInfo.color := $0080FFFF; // Giallo
    end;

    procedure tfFacTotum.leUrlInfoKeyPress(Sender: TObject; var Key: Char);
    begin
        if key = #13 then
        begin
            selectNext(sender as tWinControl, true, true);
            key := #0
        end;
    end;

    procedure tfFacTotum.leVerInfoContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    begin
        handled := true;
    end;

    procedure tfFacTotum.leVerInfoExit(sender: tObject);
    var
        taskUpdate: tTaskRecordUpdate;
    begin
        leVerInfo.text := trim( leVerInfo.text );
        if ( leVerInfo.text <> '.' )                         and
           ( length(leVerInfo.text) > 0 )                    and
           ( leVerInfo.text[length(leVerInfo.text)] <> '.' ) then
        begin
            taskUpdate         := tTaskRecordUpdate.create;
            taskUpdate.field   := dbFieldCmdVers;
            taskUpdate.value   := leVerInfo.text;
            taskUpdate.tRecord := recordCommand;
            taskUpdate.pRecord := tvConfig.selected.data;

            sTaskMgr.pushTaskToInput(taskUpdate);

            leVerInfo.color := $0080FF80 // Verde
        end
        else
            leVerInfo.color := $0080FFFF; // Giallo
    end;

    procedure tfFacTotum.leVerInfoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    begin
        // Disabilito l'utilizzo di alcuni tasti
        if key in [46] then
            key := 0;
    end;

    procedure tfFacTotum.leVerInfoKeyPress(sender: tObject; var key: char);
    var
        chrBef, chrAft: char;
    begin
        // Alla pressione del tastio Invio si attiva il tasto Tab
        if key = #13 then
        begin
            selectNext(sender as tWinControl, true, true);
            key := #0;
            exit;
        end;
        // Limito i tasti utilizzabili
        if not( charInSet(key, ['0'..'9', '.', #8]) ) then
        begin
            key := #0;
            exit;
        end;

        chrBef := #0;
        chrAft := #0;
        // Se possibile, ricavo i caratteri all'inizio e alla fine della selezione
        if (leVerInfo.selStart > 0) then
            chrBef := leVerInfo.text[leVerInfo.selStart];
        if (leVerInfo.selStart + leVerInfo.selLength) < length(leVerInfo.text) then
            chrAft := leVerInfo.text[succ(leVerInfo.selStart + leVerInfo.selLength)];

        // Il primo carattere non pu� essere un punto
        if ( (leVerInfo.selStart = 0)  and (key = '.') )             or
           ( (leVerInfo.selStart = 0)  and (leVerInfo.selLength > 0) and (chrAft = '.') and (key = #8) ) or
           ( (leVerInfo.selStart <= 1) and (leVerInfo.selLength = 0) and (chrAft = '.') and (key = #8) ) then
        begin
            key := #0;
            exit;
        end;
        // Non possono esserci due punti attaccati
        if ( ( (chrBef = '.') or (chrAft = '.') ) and (key = '.') ) then
        begin
            key := #0;
            exit;
        end;
        // Cancellando una selezione, non posso unire due punti
        if ( (chrBef = '.') and (chrAft = '.') and (key = #8) ) then
        begin
            key := #0;
            exit;
        end;
        // Cancellando, non posso unire due punti
        if ( (key = #8) and (pred(leVerInfo.selStart) > 0) ) then
            if ( (leVerInfo.text[pred(leVerInfo.selStart)] = '.') and (chrAft = '.') ) then
            begin
                key := #0;
                exit;
            end;
    end;

    procedure tfFacTotum.pmInsertClick(Sender: TObject);
    var
        taskInsert: tTaskRecordInsert;
        command:    cmdRecord;
        node:       tTreeNode;
    begin
        taskInsert   := tTaskRecordInsert.create;

        command      := cmdRecord.create;

        if assigned(tvConfig.selected) and assigned(tvConfig.selected.parent) then
        begin
            taskInsert.tRecord := recordCommand;
            taskInsert.pRecord := command;
            command.swid       := swRecord(tvConfig.selected.parent.data).guid;
            command.prty       := swRecord(tvConfig.selected.parent.data).commands.count;
            tvConfig.items.addChild(tvConfig.selected.parent, '<Nuovo Comando>').data := command;
        end
        else
        begin
            taskInsert.tRecord                    := recordSoftware;
            taskInsert.pRecord                    := swRecord.create;
            swRecord(taskInsert.pRecord).name     := '<Nuovo Software>';
            swRecord(taskInsert.pRecord).commands := tList.create;
            command.prty                          := 0;
            swRecord(taskInsert.pRecord).commands.add(command);
            node                                                  := tvConfig.items.add(nil, '<Nuovo Software>');
            node.data                                             := taskInsert.pRecord;
            tvConfig.items.addChild(node, '<Nuovo Comando>').data := command;

            node.expand(true);
        end;

        command.arch := byte(archNone);
        command.name := '<Nuovo Comando>';
        command.vers := '';
        command.cmmd := '<Comando>';
        command.uURL := '';

        sTaskMgr.pushTaskToInput(taskInsert);
    end;

    procedure tfFacTotum.pmSoftwarePopup(Sender: TObject);
    begin
        pmDelete.enabled := false;

        if assigned(tvConfig.selected) then
        begin
            if assigned(tvConfig.selected.parent) then
            begin
                pmInsert.caption := 'Inserisci comando';
                pmDelete.caption := 'Elimina comando';
            end
            else
            begin
                pmInsert.caption := 'Inserisci software';
                pmDelete.caption := 'Elimina software';
            end;
            pmDelete.enabled := true;
        end;
    end;

    procedure tfFacTotum.pmDeleteClick(sender: tObject);
    var
        taskDelete: tTaskRecordDelete;
    begin
        taskDelete := tTaskRecordDelete.create;

        if assigned(tvConfig.selected.parent) then
        begin
            taskDelete.tRecord := recordCommand;
            taskDelete.pRecord := tvConfig.selected.data;

            if tvConfig.selected.parent.count = 1 then
                tvConfig.items.delete(tvConfig.selected.parent)
            else
                tvConfig.items.delete(tvConfig.selected);
        end
        else
        begin
            taskDelete.tRecord := recordSoftware;
            taskDelete.pRecord := tvConfig.selected.data;
            tvConfig.items.delete(tvConfig.selected);
        end;

        sTaskMgr.pushTaskToInput(taskDelete);
    end;

    procedure tfFacTotum.bBrowseClick(sender: tObject);
    var
        odSelectFile: tOpenDialog;
    begin
        odSelectFile            := tOpenDialog.create(self);
        odSelectFile.initialDir := extractFilePath(application.exeName);
        odSelectFile.options    := [ofFileMustExist];
        odSelectFile.filter     := 'File Eseguibili|*.exe; *.msi|Tutti i file|*.*';

        if odSelectFile.execute then
            leCmdInfo.text      := odSelectFile.fileName;

        odSelectFile.free;
    end;

    procedure tfFacTotum.bEmptyClick(sender: tObject);
    begin
        lvEvents.items.clear;
        sEventHdlr.clearErrorCache;
        tLog.imageIndex := tImageIndex(tiEvents);
    end;

    procedure tfFacTotum.bUpdateClick(Sender: TObject);
    begin
        lvUpdate.clear;
        self.fillUpdateSoftwareList;
        self.sendUpdateSoftwareList;
    end;

    procedure tfFactotum.sendUpdateSoftwareList;
    var
        sList,
        cList:   tList;
        taskVer: tTaskGetVer;
        i,
        j:       integer;
    begin
        sList := sDBMgr.getSoftwareList;
        for i := 0 to pred(sList.count) do
        begin
            cList := swRecord( sList.items[i] ).commands;
            for j := 0 to pred(cList.count) do
            begin
                if (cmdRecord( cList.items[j] ).uURL = '') or (cmdRecord( cList.items[j] ).vers = '') then // TODO: Controlla meglio che l'url sia valido
                    continue;

                taskVer        := tTaskGetVer.create;
                taskVer.cmdRec := cmdRecord( cList.items[j] );
                sTaskMgr.pushTaskToInput(taskVer);
            end;
        end;
    end;

    procedure tfFactotum.fillUpdateSoftwareList;
    var
      sList,
      cList:  tList;
      cmdRec: cmdRecord;
      i,
      j:      integer;
    begin
        sList := sDBMgr.getSoftwareList;
        for i := 0 to pred(sList.count) do
        begin
            cList := swRecord( sList.items[i] ).commands;
            for j := 0 to pred(cList.count) do
            begin
                cmdRec  := cList.items[j];

                if (cmdRec.uURL = '') or (cmdRec.vers = '') then // TODO: Controlla meglio che l'url sia valido
                    continue;

                with lvUpdate.items.add do
                begin
                    caption := '';
                    subItems.add( cmdRec.name );
                    subItems.add( cmdRec.vers );
                    imageIndex := tImageIndex(eiDotYellow);
                end;
            end;
        end;
    end;

    end.

