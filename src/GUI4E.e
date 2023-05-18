OPT OSVERSION=40,PREPROCESS

#ifndef EVO_3_6_0
    FATAL('Requires E-VO compiler version 3.6.0 or newer')
#endif

#date VER 'GUI4E v0.1 (%d.%aM.%y) by Samuel D. Crow'

MODULE 'intuition/intuition','intuition/screens',
    'graphics/gfx','graphics/modeid',
    'dos/dos','dos/rdargs',
    'workbench/startup','workbench/workbench'

ENUM ERR_OK, ERR_TOOL

CONST SCREENWIDTH=640
CONST TOOLWIDTH=32 -> 16 Low Res pixels
CONST WINDOWWIDTH=SCREENWIDTH-TOOLWIDTH

-> Globals are prefixed with g_ and defined here
DEF g_idcmp, g_scrn, g_wndw, g_tool, g_log

PROC trace(msg,var=NIL)
    #ifdef DEBUG
    IF var
        VfPrintf(g_log,msg,var)
    ELSE
        Fputs(g_log,msg)
    ENDIF
    Flush(g_log)
    #endif
ENDPROC

-> don't break these up
    CHAR '$VER:'
title: CHAR VER,0

PROC openFile(file)
    DEF buf[144]:STRING
    RightStr(buf,file,4)
    UpperStr(buf)
    IF StrCmp(buf,'.GUI')
        RETURN
    ENDIF
    trace('Skipping illegal filename "\s".\n',file)
ENDPROC

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
    trace('Arguments passed: %ld.\n', ListLen(files2))
    ForAll({x},files2,`openFile(x))
ENDPROC

PROC setup()
    IF (g_scrn:=OpenScreenTagList(NIL, [
        SA_WIDTH, SCREENWIDTH,
        SA_DEPTH, 4,
        SA_TITLE, {title},
        SA_DISPLAYID, HIRESLACE_KEY,
        TAG_DONE
        ]))=NIL THEN Raise('SCR')
    trace('Opened main screen successfully.\n')
    IF (g_wndw:=OpenWindowTagList(NIL, [
        WA_LEFT, TOOLWIDTH,
        WA_WIDTH, WINDOWWIDTH,
        WA_DRAGBAR, TRUE,
        WA_SIZEGADGET, TRUE,
        WA_DEPTHGADGET, TRUE,
        WA_CLOSEGADGET, TRUE,
        WA_NEWLOOKMENUS, TRUE,
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

PROC main() HANDLE
#ifdef DEBUG
    g_log:=Open('GUI4E.log',MODE_NEWFILE)
#endif
    setup()
    processArgs()
EXCEPT
    SELECT exception
        CASE ERR_OK
            -> No errors so do nothing
            trace('Exiting successfully.\n')
        CASE 'ARGS'
            WriteF('Arguments could not be read.\n')
        CASE 'SPR'
            WriteF('Could not allocate appropriate sprite.\n')
        CASE 'SCR'
            WriteF('Could not open custom screen.\n')
        CASE 'WIN'
            WriteF('Could not open window.\n')
        CASE ERR_TOOL
            WriteF('Could not open toolbar window.\n')
        CASE 'MEM'
            WriteF('Out of RAM.\n')
        DEFAULT
            WriteF('An unhandled exception occurred numbered \d.\n', exception)
    ENDSELECT
    CloseWindow(g_tool)
    CloseWindow(g_wndw)
    CloseScreen(g_scrn)
#ifdef DEBUG
    Close(g_log)
#endif
ENDPROC
