OPT OSVERSION=40,PREPROCESS

#ifndef EVO_3_6_0
    FATAL('Requires E-VO compiler version 3.6.0 or newer')
#endif

#ifdef DEBUG
    #define TRACE WriteF
#else
    #define TRACE ->
#endif

MODULE 'intuition/intuition','graphics/gfx','dos/dos'

ENUM ERR_OK

CONST NAME='GUI for E'

DEF g_idcmp,g_scrn,g_wndw

PROC openFile(file)
    DEF buf[144]:STRING
    RightStr(buf,file,4)
    UpperStr(buf)
    IF StrCmp(buf,'.GUI')
        RETURN
    ENDIF
    TRACE('Skipping illegal filename "\s"\n',file)
ENDPROC

PROC processArgs()
    DEF rdargs:PTR TO RdArgs,
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
        IF (rdargs:=ReadArgs('FILE/M',files,NIL))=NIL THEN Raise('ARGS')
        files2:=List(ListMax(files))
        ListCopy(files,files2)
        FreeArgs(rdargs)
    ENDIF
    ForAll({x},files2,`openFile(x))
ENDPROC

PROC setup()
    g_scrn:=OpenS(640,256,4,0,NAME)
    g_wndw:=OpenW(16,0,624,256,
        g_idcmp,WFLG_BORDERLESS|WFLG_BACKDROP,NAME,g_scrn,NIL)
ENDPROC

PROC main() HANDLE
    setup()
    processArgs()
EXCEPT
    SELECT exception
        CASE ERR_OK
            -> No errors so do nothing
        CASE 'ARGS'
            WriteF('Arguments couldn\'t be read.\n')
        CASE 'SPR'
            WriteF('Couldn\t allocate appropriate sprite.')
        CASE 'SCR'
            WriteF('Couldn\'t open custom screen.')
        CASE 'WIN'
            WriteF('Couldn\'t open window.')
        CASE 'MEM'
            WriteF('Out of RAM.\n')
        DEFAULT
            WriteF('An unhandled exception occurred numbered \d.\n', exception)
    ENDSELECT
ENDPROC
