OPT OSVERSION=40,PREPROCESS

#ifndef EVO_3_6_0
    FATAL('Requires E-VO compiler version 3.6.0 or newer')
#endif

#date VER '$VER: GUI4E v0.1 (%d.%aM.%y) by Samuel D. Crow'

MODULE 'intuition/intuition','intuition/screens',
    'graphics/gfx','graphics/modeid',
    'dos/dos','dos/rdargs',
    'workbench/startup','workbench/workbench',
    '*toolbar/toolbar'

ENUM ERR_OK

CONST NAME='GUI for E'
CONST SCREENWIDTH=640
CONST TOOLWIDTH=32 -> 16 Low Res pixels
CONST WINDOWWIDTH=SCREENWIDTH-TOOLWIDTH

-> Globals are prefixed with g_ and defined here
DEF g_idcmp, g_scrn, g_wndw, g_tool:PTR TO toolbar

#ifdef DEBUG
DEF g_log
PROC trace(msg,var=NIL)
    IF var
        VfPrintf(g_log,msg,var)
    ELSE
        Fputs(g_log,msg)
    ENDIF
    Flush(g_log)
ENDPROC
#else
PROC trace(msg,var=NIL) IS RETURN
#endif

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
        wb:=wbmessage
        wbArguments:=wb.arglist
        files:=List(wb.numargs)
        CopyMem({wbArguments},{files2},wb.numargs)
    ELSE -> launched from command line
        IF (rargs:=ReadArgs('FILE/M',files,NIL))=NIL THEN Raise('ARGS')
        files2:=List(ListMax(files))
        ListCopy(files,files2)
        FreeArgs(rargs)
    ENDIF
    ForAll({x},files2,`openFile(x))
ENDPROC

PROC setup()
    IF (g_scrn:=OpenScreenTagList(NIL, [
        SA_WIDTH, SCREENWIDTH,
        SA_DEPTH, 4,
        SA_TITLE, NAME,
        SA_DISPLAYID, HIRESLACE_KEY,
        TAG_DONE
        ]))=NIL THEN Raise('SCR')
    trace('Opened main screen successfully.\n')
    IF (g_wndw:=OpenWindowTagList(NIL, [
        WA_LEFT, TOOLWIDTH,
        WA_TOP, 0,
        WA_WIDTH, WINDOWWIDTH,
        WA_IDCMP, g_idcmp,
        WA_CUSTOMSCREEN, g_scrn,
        TAG_DONE
        ]))=NIL THEN Raise('WIN')
    trace('Opened main window successfully.\n')
    NEW g_tool.create(0,0,200,NIL)
ENDPROC

version: CHAR VER,0

PROC main() HANDLE
#ifdef DEBUG
    g_log:=Open('GUI4E.log',MODE_NEWFILE)
#endif
    trace('\s\n',{version})
    setup()
    processArgs()
EXCEPT
    SELECT exception
        CASE ERR_OK
            -> No errors so do nothing
        CASE 'ARGS'
            WriteF('Arguments could not be read.\n')
        CASE 'SPR'
            WriteF('Could not allocate appropriate sprite.')
        CASE 'SCR'
            WriteF('Could not open custom screen.')
        CASE 'WIN'
            WriteF('Could not open window.')
        CASE 'MEM'
            WriteF('Out of RAM.\n')
        DEFAULT
            WriteF('An unhandled exception occurred numbered \d.\n', exception)
    ENDSELECT
    g_tool.free()
    CloseWindow(g_wndw)
    CloseScreen(g_scrn)
ENDPROC
