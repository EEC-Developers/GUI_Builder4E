OPT OSVERSION=40,PREPROCESS

#ifndef EVO_3_6_0
    FATAL('Requires E-VO compiler version 3.6.0 or newer')
#endif

#date VER 'GUI4E v0.1 (%d.%aM.%y) by Samuel D. Crow'

MODULE 'intuition/intuition','intuition/screens',
    'graphics/gfx','graphics/modeid',
    'dos/dos','dos/rdargs',
    'workbench/startup','workbench/workbench'

ENUM ERR_OK, ERR_TOOL, ERR_FILE

RAISE ERR_FILE IF Fopen()=NIL

CONST SCREENWIDTH=640
CONST TOOLWIDTH=32 -> 16 Low Res pixels
CONST WINDOWWIDTH=SCREENWIDTH-TOOLWIDTH
CONST ALLBITSSET=-1 -> NOT 0 for unsigned

-> Globals are prefixed with g_ and defined here
DEF g_idcmp, g_scrn, g_wndw, g_tool, g_log

PROC trace(msg,val=ALLBITSSET)
#ifdef DEBUG
    IF val=ALLBITSSET
        Fputs(g_log,msg)
    ELSE
        VfPrintf(g_log,msg,val)
    ENDIF
    Flush(g_log)
#endif
ENDPROC

PROC openFile(file)
    DEF buf[144]:STRING
    RightStr(buf,file,4)
    UpperStr(buf)
    IF StrCmp(buf,'.GUI')
        RETURN
    ENDIF
    trace('Skipping illegal filename "\s".\n',file)
ENDPROC

-> don't break these up
    CHAR '$VER:'
title: CHAR VER,0

PROC processArgs()
    DEF rargs:PTR TO rdargs,
        wb:PTR TO wbstartup,
        wbArguments:PTR TO wbarg,
        files:PTR TO LONG,
        files2,
        x
    IF wbmessage -> launched from Workbench
        trace('Parsing WB icon arguments.\n')
        wb:=wbmessage
        wbArguments:=wb.arglist
        files:=List(wb.numargs)
        CopyMem({wbArguments},{files2},wb.numargs)
    ELSE -> launched from command line
        trace('Parsing CLI arguments.\n')
        IF (rargs:=ReadArgs('FILE/M',files,NIL))=NIL THEN Raise('ARGS')
        files2:=List(ListMax(files))
        ListCopy(files,files2)
        FreeArgs(rargs)
    ENDIF
    trace('Arguments passed: \u.\n', ListLen(files2))
    ForAll({x},files2,`openFile(x))
ENDPROC

PROC setup()
    IF (g_scrn:=OpenScreenTagList(NIL, [
        SA_WIDTH, SCREENWIDTH,
        SA_DEPTH, 4,
        SA_PENS, [ALLBITSSET],
        SA_TITLE, {title},
        SA_DISPLAYID, HIRESLACE_KEY,
        TAG_DONE
        ]))=NIL THEN Raise('SCR')
    trace('Opened main screen successfully.\n')
    IF (g_wndw:=OpenWindowTagList(NIL, [
        WA_LEFT, TOOLWIDTH,
        WA_WIDTH, WINDOWWIDTH,
        WA_FLAGS, WFLG_DRAGBAR OR WFLG_SIZEGADGET OR WFLG_DEPTHGADGET OR
            WFLG_NEWLOOKMENUS OR WFLG_CLOSEGADGET,
        WA_CUSTOMSCREEN, g_scrn,
        TAG_DONE
        ]))=NIL THEN Raise('WIN')
    trace('Opened main window successfully.\n')
    IF (g_tool:=OpenWindowTagList(NIL, [
        WA_LEFT, 0,
        WA_WIDTH, TOOLWIDTH,
        WA_BACKDROP, TRUE,
        WA_BORDERLESS, TRUE,
        WA_CUSTOMSCREEN, g_scrn,
        TAG_DONE
    ]))=NIL THEN Raise(ERR_TOOL)
    trace('Opened the toolbar window successfully.\n')
ENDPROC

PROC shutdown()
    CloseWindow(g_tool)
    CloseWindow(g_wndw)
    CloseScreen(g_scrn)
ENDPROC

PROC main() HANDLE
#ifdef DEBUG
    g_log:=Fopen('GUI4E.log',NEWFILE)
#endif
    setup()
    processArgs()
    shutdown()
EXCEPT
    SELECT exception
        CASE ERR_OK
            -> No errors so do nothing
            trace('Exiting successfully.\n')
        CASE 'ARGS'
            PutStr('Arguments could not be read.\n')
        CASE 'SPR'
            PutStr('Could not allocate appropriate sprite.\n')
        CASE 'SCR'
            PutStr('Could not open custom screen.\n')
        CASE 'WIN'
            PutStr('Could not open window.\n')
        CASE ERR_TOOL
            PutStr('Could not open toolbar window.\n')
        CASE ERR_FILE
            PutStr('Could not open a file.\n')
        CASE 'MEM'
            PutStr('Out of RAM.\n')
        DEFAULT
            PrintF('An unhandled exception occurred numbered \d.\n', exception)
    ENDSELECT
    shutdown()
ENDPROC
